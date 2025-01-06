/* ======================= */
/* Importation des données clients depuis le fichier client.csv */
/* ======================= */
proc import DATAFILE="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Données\clients.csv"
    OUT=donnees.clients
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DELIMITER=";";
RUN;

/* ======================= */
/* Renommage de la colonne VAR3 pour améliorer la lisibilité */
/* ======================= */
data donnees.clients;
    set donnees.clients;
    rename VAR3 = date_inscription;
run;

/* ======================= */
/* Vérification du nombre de lignes dans la table clients */
/* ======================= */
proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.clients;
quit;

/* ======================= */
/* Vérification du nombre de colonnes dans la table clients */
/* ======================= */
proc sql;
    select count(*) as Nombre_de_colonnes
    from dictionary.columns
    where libname = "DONNEES" and memname = "CLIENTS";
quit;

/* ======================= */
/* Comptage du nombre de clients uniques */
/* ======================= */
proc sql;
    select count(distinct num_client) as Nombre_clients_uniques
    from donnees.clients;
quit;

/* ======================= */
/* Vérification des valeurs manquantes par colonne */
/* ======================= */
proc sql;
    select 
        sum(num_client = "") as num_client_missing,
        sum(actif = .) as actif_missing,
        sum(date_inscription = .) as date_inscription_missing,
        sum(A_ete_parraine = "") as A_ete_parraine_missing,
        sum(Genre = "") as Genre_missing,
        sum(date_naissance = .) as date_naissance_missing,
        sum(inscrit_NL = .) as inscrit_NL_missing
    from donnees.clients;
quit;

/* ======================= */
/* Identification des dates minimales et maximales */
/* ======================= */
proc sql;
    select min(date_inscription) as Min_date_creation format=ddmmyy10.,
           max(date_inscription) as Max_date_creation format=ddmmyy10.,
           min(date_naissance) as Min_date_naissance format=ddmmyy10.,
           max(date_naissance) as Max_date_naissance format=ddmmyy10.
    from donnees.clients;
quit;

/* ======================= */
/* Analyse de la distribution des variables qualitatives */
/* ======================= */
proc freq data=donnees.clients;
    tables Genre A_ete_parraine actif inscrit_NL / nocum;
run;

/* ======================= */
/* Création de nouvelles variables : âge et année-mois d'inscription */
/* ======================= */
data donnees.clients_MEF;
    set donnees.clients; 
    age_client = intck('year', date_naissance, '01JAN2024'd); /* Calcul de l'âge en années */
    an_mois_inscription = cats(year(date_inscription), '_', put(month(date_inscription), z2.)); /* Format année-mois */
run;

/* ======================= */
/* Comptage des inscriptions par mois et année */
/* ======================= */
proc freq data=donnees.clients_mef;
    table an_mois_inscription / out=freq_inscription_an_mois nocum;
run;

/* ======================= */
/* Création de statistiques descriptives pour les clients */
/* ======================= */
/* Création de statistiques descriptives pour les clients */
proc sql;
    create table resultat.stat_client as 
    select 
        count(distinct(num_client)) as nb_client,
        sum(actif=1) as compte_ouvert,
        sum(inscrit_NL=1) as inscrit_NL,
        sum(genre="Femme") as Madame,
        sum(genre="Homme") as Monsieur,
        sum(genre not in ("Homme","Femme")) as civilite_NR,
        sum((age_client<=0) + (age_client>100)) as age_Non_renseigne,
        sum(0<age_client<25) as age_Moins_de_25_ans,
        sum(25<=age_client<35) as age_25_34_ans,
        sum(35<=age_client<45) as age_35_44_ans,
        sum(45<=age_client<55) as age_45_54_ans,
        sum(55<=age_client<65) as age_55_64_ans,
        sum(65<=age_client<100) as age_65_ans_plus,
        mean(age_client) as age_moyen
    from donnees.clients_MEF;
quit;

/* Transformation des statistiques descriptives en format vertical */
proc transpose data=resultat.stat_client out=resultat.stat_client_vertical(rename=(col1=value));
    var nb_client compte_ouvert inscrit_NL Madame Monsieur civilite_NR
        age_Non_renseigne age_Moins_de_25_ans age_25_34_ans age_35_44_ans 
        age_45_54_ans age_55_64_ans age_65_ans_plus age_moyen;
run;
/* ======================= */
/* Importation des données commandes depuis un fichier CSV */
/* ======================= */
PROC IMPORT DATAFILE="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Données\commandes.csv"
    OUT=donnees.commandes
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DELIMITER=";";
RUN;

/* Vérification du nombre de lignes dans la table commandes */
proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.commandes;
quit;

/* Vérification du nombre de colonnes dans la table commandes */
proc sql;
    select count(*) as Nombre_de_colonnes
    from dictionary.columns
    where libname = "DONNEES" and memname = "COMMANDES";
quit;

/* ======================= */
/* Nettoyage des noms de mois et conversion en format date SAS */
/* ======================= */
data donnees.commandes;
    set donnees.commandes;

    /* Transformation des noms de mois en anglais */
    date_modifiee = tranwrd(date, "janv", "jan");
    date_modifiee = tranwrd(date_modifiee, "févr", "feb");
    date_modifiee = tranwrd(date_modifiee, "mars", "mar");
    date_modifiee = tranwrd(date_modifiee, "avr", "apr");
    date_modifiee = tranwrd(date_modifiee, "mai", "may");
    date_modifiee = tranwrd(date_modifiee, "juin", "jun");
    date_modifiee = tranwrd(date_modifiee, "juil", "jul");
    date_modifiee = tranwrd(date_modifiee, "août", "aug");
    date_modifiee = tranwrd(date_modifiee, "sept", "sep");
    date_modifiee = tranwrd(date_modifiee, "oct", "oct");
    date_modifiee = tranwrd(date_modifiee, "nov", "nov");
    date_modifiee = tranwrd(date_modifiee, "déc", "dec");

    /* Conversion en format date SAS */
    date_sas = input(date_modifiee, date9.);
    format date_sas date9.;
run;

/* Affichage des 10 premières lignes avec les colonnes modifiées */
proc print data=donnees.commandes(obs=10);
    var date date_modifiee date_sas;
run;

/* Vérification du nombre de lignes dans la table commandes modifié */
proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.commandes;
quit;

/* Identification des valeurs minimales et maximales pour les montants et les dates */
proc sql;
    select
           min(date) as Min_date,
           max(date) as Max_date,
           min(montant_des_produits) as min_montant_produits,
           max(montant_des_produits) as max_montant_produits,
           min(abs(remise_sur_produits)) as min_remise_produits,
           max(abs(remise_sur_produits)) as max_remise_produits,
           min(montant_livraison) as min_montant_livraison,
           max(montant_livraison) as max_montant_livraison,
           min(abs(remise_sur_livraison)) as min_remise_livraison,   
           max(abs(remise_sur_livraison)) as max_remise_livraison,
           min(montant_total_paye) as min_montant_total,
           max(montant_total_paye) as max_montant_total
    from donnees.commandes;
quit;

/* Vérification des valeurs manquantes par colonne */
proc sql;
    select 
        sum(num_client = "") as num_client_missing,
        sum(numero_commande = .) as num_commande_missing,
        sum(date = "") as date_missing,
        sum(montant_des_produits = .) as montant_produit_missing,
        sum(montant_livraison = .) as montant_livraison_missing,
        sum(montant_total_paye = .) as montant_total_missing
    from donnees.commandes;
quit;

/* Filtrage des commandes pour ne conserver que les lignes complètes */
data donnees.commandes_nettoye;
    set donnees.commandes;
    if montant_des_produits ne . and montant_livraison ne . and montant_total_paye ne .;
run;

/* Vérification du nombre de lignes dans la table commandes nettoye */
proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.commandes_nettoye;
quit;
/* Comptage des clients uniques dans les commandes nettoyé */
proc sql;
    select count(distinct num_client) as Nombre_clients_uniques
    from donnees.commandes_nettoye;
quit;

/* ======================= */
/* Suppression des doublons dans clients et commandes */
/* ======================= */
proc sort data=donnees.clients_MEF nodupkey out=donnees.clients_unique;
    by num_client;
run;

proc sort data=donnees.commandes nodupkey out=donnees.commandes_unique;
    by num_client;
run;

/* ======================= */
/* Identification des clients sans commandes */
/* ======================= */
proc sql;
    create table resultat.clients_sans_commandes as
    select distinct c.num_client
    from donnees.clients_unique c
    where c.num_client not in (select num_client from donnees.commandes_unique);
quit;


proc sql;
    select count(*) as Nombre_Inscrits_NL_and_Actif
    from Resultat.Clients_sans_commandes
    where inscrit_NL = 1 and actif = 1;
quit;

/* ======================= */
/* Export des données nettoyées */
/* ======================= */
proc export data=resultat.clients_nettoyes_avec_flag
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\clients_nettoyes.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

proc export data=donnees.commandes_unique
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\commandes_nettoyees.csv"
    dbms=csv
    replace;
    delimiter=";";
run;
