# 📈 Projet de Segmentation RFM pour un Site E-Commerce

## 🔖 Description du projet
Ce projet a pour objectif d’effectuer une segmentation RFM (✅ Récence, ✅ Fréquence, ✅ Montant) des clients à partir des données de commandes et de clients. Cette analyse est essentielle pour identifier des groupes de clients homogènes en termes de comportement d’achat, permettant ainsi d’orienter les stratégies marketing de manière optimale pour un site e-commerce de vente.

## 📂 Structure des fichiers

- **📄 Scripts SAS** : Fichier principal contenant les étapes de nettoyage et  calcul des indicateurs RFM et des segmentations.
- **📁 Données brutes** :
  - `clients.csv` : Informations sur les clients.
  - `commandes.csv` : Historique des commandes.
- **📈 Résultats exportés** :
  - `indicateur_RFM.csv` : Indicateurs RFM calculés pour chaque client.
  - `segment_RFM_final.csv` : Segments RFM finaux.
  - `Distribution_RFM.csv` : Distribution des segments RFM.
  - `clients_nettoyes.csv` : Données clients nettoyées avec un flag indiquant les clients sans commandes.
  - `commandes_nettoyees.csv` : Données des commandes nettoyées.

## 🔢 Processus de segmentation

1. **🔢 Calcul des indicateurs RFM** :
   - ⏳ Récence (temps écoulé depuis la dernière commande en mois).
   - ♻️ Fréquence (nombre de commandes distinctes).
   - 💵 Montant total payé.

2. **🔀 Segmentation RFM** :
   - Attribution des scores R, F, et M selon des seuils définis.
   - Regroupement en segments combinés (⬆️ RFM1 ➖ RFM9 ⬇️).

3. **🔍 Export et visualisation des résultats** :
   - Distribution des segments.
   - Croisements des segments Récence, Fréquence et Montant.

## 🔧 Outils utilisés
- **SAS 🔢** : Traitement des données et calculs des indicateurs RFM.
- **Tableau 🔬** : Visualisation des résultats via des dashboards.
- **Excel 📄** : Export des données pour analyses supplémentaires.
- **Latex 📀** : Présentation des conclusions dans des slides explicatifs.

## 🔔 Instructions pour réplication

1. **🔄 Import des données** :
   - Importer les fichiers CSV dans SAS.
   - Vérifier l’intégrité des données (⚠️ valeurs manquantes, ❌ doublons).

2. **🚀 Exécution des étapes SAS** :
   - Lancer les scripts dans l’ordre pour nettoyer, transformer et analyser les données.

3. **🔍 Analyse des résultats** :
   - Utiliser Tableau pour interpréter les dashboards basés sur les exports.
   - Réaliser des analyses croisées pour détecter des tendances.

## 🎉 Conclusion
Le projet a permis d’identifier des segments clés dans la base clients. 🌐 Ces segments constituent une base solide pour personnaliser les campagnes marketing et améliorer la fidélisation et la valeur à vie des clients. 

## 📢 Distributeurs
Voici les informations des membres du projet :

- **👤 Distributeur 1** : [Lina Benzemma]  
  🛠️ GitHub : [https://github.com/linabnz]  
  📧 Email : [lina.benzemma@yahoo.com]

- **👤 Distributeur 2** : [Gaétan Dumas]  
  🛠️ GitHub : [https://github.com/gaetan250]  
  📧 Email : [gaxtandms@gmail.com]

- **👤 Distributeur 3** : [Sharon Chemmama]  
  🛠️ GitHub : [https://github.com/Sharon2607]  
  📧 Email : [chemmamasharon@gmail.com]

- **👤 Distributeur 4** : [Pierre Liberge]  
  🛠️ GitHub : [https://github.com/pierreliberge]  
  📧 Email : [pierreliberge2@gmail.com]