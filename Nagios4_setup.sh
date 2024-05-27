#!/bin/bash

echo "----------------------------------------------------------------"
# Vérifier si l'utilisateur a les droits d'administration
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté avec les privilèges d'administration (utilisez sudo)." 1>&2
  exit 1
fi

# Installation du serveur web apache2 et de nagios4
echo "Voulez-vous installer les paquets Apache2 et Nagios4 ? (Y/N)"
read rep
#Vérification de la demande de l'utilisateur
if [[ "$rep" == "N" || "$rep" == "n" ]]; then
    echo "-----------------------------------------------------------"
else
    echo "-----------------------------------------------------------"
    echo "Installation de Apache2"
    apt-get update
    apt-get install apache2
    # Vérifier si l'installation a réussi
    if [ $? -eq 0 ]; then
        echo "apache2 a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de apache2."
        exit 1
    fi
    echo "-----------------------------------------------------------"
    echo "Installation de Nagios4"
    apt-get install nagios4
    # Vérifier si l'installation a réussi
    if [ $? -eq 0 ]; then
        echo "Nagios4 a été installé avec succès."
    else
        echo "Une erreur s'est produite lors de l'installation de Nagios4."
        exit 1
    fi
    echo "-----------------------------------------------------------"
    echo "Installation de d'apache2 et de nagios4 terminée"
fi
echo "-----------------------------------------------------------"
echo "Avez-vous déjà fait l'installation et la configuration pour la prise en compte de la connexion via des identifiants ? (Y/N)"
read rep
if [[ "$rep" == "N" || "$rep" == "n" ]]; then
    #Prise en compte des fichiers cgi pour apache2
    echo "-----------------------------------------------------------"
    echo "Modification des fichiers de configuration de apache2 pour la prise en compte des fichiers cgi"
    sudo a2enmod rewrite cgi
    #Modification des fichiers de nagios4 pour un accès uniquement avec identifiants
    echo "-----------------------------------------------------------"
    echo "Modification des fichiers de nagios4 pour un accès uniquement avec identifiants"
    nagios4_cgi="/etc/apache2/conf-available/nagios4-cgi.conf"
    line_number=15
    line_ajoute='  AuthDigestDomain "Nagios4"
    AuthDigestProvider file
    AuthUserFile "/etc/nagios4/htdigest.users"
    AuthGroupFile "/etc/group"
    AuthName "Restricted Nagios4 Access"
    AuthType Digest
    Require valid-user'
    # Utilisation de sed pour insérer après une ligne spécifique
    sed -i "${line_number}a\\
    $(echo "$line_ajoute" | sed 's/$/\\/')
    " $nagios4_cgi

    #Suppression des lignes Files et IpRequired
    sed -i '43,54d' $nagios4_cgi

    #Création du mot de passe administrateur de nagios4
    echo "----------------------------------------------------------------"
    echo "Création du mot de passe administrateur de nagios4 (Il faut s'en souvenir)"
    sudo htdigest -c /etc/nagios4/htdigest.users "Restricted Nagios4 Access" nagiosadmin

    #Prise en compte de l'authentification par identifiant
    cgi_cfg="/etc/nagios4/cgi.cfg"
    line_number=76
    nouvelle_ligne="use_authentication = 1"
    sed -i "${line_number}d" "$cgi_cfg"
    sed -i "${line_number}i$nouvelle_ligne" "$cgi_cfg"

    #Redémarrage des services
    echo "----------------------------------------------------------------"
    echo "Redémarrage des services"
    sudo systemctl restart nagios4
    sudo systemctl restart apache2
fi

#Exemple pour LinuxHost
string="cfg_file=/etc/nagios4/objects/linuxhosts.cfg" 
file="/etc/nagios4/objects/linuxhosts.cfg"
# Création du texte d'exemple à ajouter
texte="#define host { 
    #use linux-server
    #host_name Ubuntu-Host
    #alias Ubuntu-Host
    #address 192.168.1.15
    #hostgroups host_ubuntu
#}"
group_text="#define hostgroup {
    #hostgroup_name host_ubuntu
    #alias Ubuntu Host Group
#}"
echo "$texte $group_text" > $file

cd ..
rm -rf Nagios4
echo "Configuration terminée"
echo "----------------------------------------------------------------"
