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
    exit 1
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
#Prise en compte des fichiers cgi pour apache2
echo "-----------------------------------------------------------"
echo "Modification des fichiers de configuration de apache2 pour la prise en compte des fichiers cgi"
sudo a2enmod rewrite cgi
#Modification des fichiers de nagios4 pour un accès uniquement avec identifiants
echo "-----------------------------------------------------------"
echo "Modification des fichiers de nagios4 pour un accès uniquement avec identifiants"
nagios4_cgi="/etc/apache2/conf-available/nagios4-cgi.conf"
line_number=15
line_ajoute='AuthDigestDomain "Nagios4"
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
