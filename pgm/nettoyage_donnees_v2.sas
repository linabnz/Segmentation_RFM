/* --- 1. Déclaration des bibliothèques --- */
LIBNAME resultat 'C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat';
LIBNAME donnees 'C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données';

/*FICHIER CLIENTS*/
PROC IMPORT DATAFILE="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données\clients.csv"
    OUT=donnees.clients
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DELIMITER=";";
RUN;

proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.clients;
quit;

proc sql;
    select count(*) as Nombre_de_colonnes
    from dictionary.columns
    where libname = "DONNEES" and memname = "CLIENTS";
quit;

proc sql;
    select count(distinct num_client) as Nombre_clients_uniques
    from donnees.clients;
quit;
proc sql;
    select 
        sum(num_client = "") as num_client_missing,
        sum(actif = .) as actif_missing,
        sum(VAR3 = .) as date_création_compte_missing,
        sum(A_ete_parraine = "") as A_ete_parraine_missing,
        sum(Genre = "") as Genre_missing,
        sum(date_naissance = .) as date_naissance_missing,
        sum(inscrit_NL = .) as inscrit_NL_missing
    from donnees.clients;
quit;
proc sql;
    select min(VAR3) as Min_date_creation format=ddmmyy10.,
           max (VAR3) as Max_date_creation format=ddmmyy10.,
           min (date_naissance) as Min_date_naissance format=ddmmyy10.,
           max(date_naissance) as Max_date_naissance format=ddmmyy10.
    from donnees.clients;
quit;

proc freq data=donnees.clients;
    tables Genre A_ete_parraine actif inscrit_NL / nocum;
run;
data donnees.clients_MEF;
    set donnees.clients; 
    age_client = intck('year', date_naissance, '01JAN2024'd) ;
    an_mois_inscription = cats(year(VAR3), '_', put(month(VAR3), z2.)); 
run;

proc freq data=donnees.clients_mef;
table an_mois_inscription / 
out= freq_inscription_an_mois nocum ;
run;


/*FICHIER COMMANDES*/
PROC IMPORT DATAFILE="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données\commandes.csv"
    OUT=donnees.commandes
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    DELIMITER=";";
RUN;

proc sql;
    select count(*) as Nombre_de_lignes
    from donnees.commandes;
quit;

proc sql;
    select count(*) as Nombre_de_colonnes
    from dictionary.columns
    where libname = "DONNEES" and memname = "COMMANDES";
quit;

proc sql;
    select count(distinct num_client) as Nombre_clients_uniques
    from donnees.commandes;
quit;

proc sql;
    select
           min (date) as Min_date,
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

data donnees.commandes_nettoye;
    set donnees.commandes;
    if montant_des_produits ne . and montant_livraison ne . and montant_total_paye ne .;
run;

proc sql;
    create table stat_client as 
    select 
        count(distinct(num_client)) as nb_client,
        sum(actif=1) as compte_ouvert,
        sum(inscrit_NL=1) as inscrit_NL,
        sum(genre="Femme") as Madame,
        sum(genre="Homme") as Monsieur,
        sum(genre not in ("Homme","Femme")) as civilite_NR,
        sum((age_client<=0) + (age_client>100)) as age_Non_renseigne,
        sum(0<age_client<25) as age_Moins_de_25_ans,
        sum(25<=age_client<35) as age_25_35_ans,
        sum(35<=age_client<45) as age_35_45_ans,
        sum(45<=age_client<55) as age_45_55_ans,
        sum(55<=age_client<65) as age_55_65_ans,
        sum(65<=age_client<100) as age_plus_de_65_ans,
        mean(age_client) as age_moyen
    from donnees.clients_MEF;
quit;

proc transpose data=stat_client out=donnees.stat_client_vertical(rename=(col1=value));
    var nb_client compte_ouvert inscrit_NL Madame Monsieur civilite_NR
        age_Non_renseigne age_Moins_de_25_ans age_25_35_ans age_35_45_ans 
        age_45_55_ans age_55_65_ans age_plus_de_65_ans age_moyen;
run;


proc sql;
    create table clients_sans_commandes as
    select distinct c.num_client, c.*
    from donnees.clients c
    where c.num_client not in (select distinct num_client from donnees.commandes);
quit;

proc sql;
    select count(*) as nb_clients_sans_commandes
    from clients_sans_commandes;
quit;


data donnees.commandes;
    set donnees.commandes;

    /* Remplacement des mois français par des mois reconnus par SAS */
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

    /* Conversion de texte modifié en format Date SAS */
    date_sas = input(date_modifiee, date9.);
    format date_sas date9.; /* Appliquer le format de date SAS */
run;

proc print data=donnees.commandes(obs=10);
    var date date_modifiee date_sas;
run;


/* Enregistrement des tables clients et commandes après nettoyage/modification */

/* Export de la table clients_MEF */
proc export data=donnees.clients_mef
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données\clients_nettoyes.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* Export de la table commandes_nettoye */
proc export data=donnees.Commandes
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données\commandes_nettoyees.csv"
    dbms=csv
    replace;
    delimiter=";";
run;
