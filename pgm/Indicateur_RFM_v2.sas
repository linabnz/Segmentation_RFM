/* --- Déclaration des bibliothèques --- */
libname resultat 'C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat';
libname donnees 'C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Données';

/* --- Étape 1 : Calcul des indicateurs RFM --- */
proc sql;
    create table resultat.indicateur_RFM as
    select
        num_client,
        min(intck('month', date_sas, "01JAN2023"d)) as recence,
        count(distinct numero_commande) as frequence,
        sum(montant_total_paye) as montant
    from donnees.commandes
    group by num_client;
quit;

/* --- Étape 2 : Application des seuils RFM --- */
data resultat.application_seuil;
    set resultat.indicateur_RFM;
    /* Segmentation de la récence */
    if 17 < recence then seg_recence = "R1";
    else if 7 < recence <= 16 then seg_recence = "R2";
    else if recence <= 7 then seg_recence = "R3";
    else seg_recence = "?";

    /* Segmentation de la fréquence */
    if frequence = 1 then seg_frequence = "F1";
    else if 2 <= frequence <= 3 then seg_frequence = "F2";
    else if 3 < frequence then seg_frequence = "F3";
    else seg_frequence = "?";

    /* Segmentation du montant */
    if montant < 75 then seg_montant = "M1";
    else if 75 <= montant < 292 then seg_montant = "M2";
    else if montant >= 292 then seg_montant = "M3";
    else seg_montant = "?";
run;

/* --- Étape 3 : Application des segments combinés RF --- */
data resultat.application_seuil_RF;
    set resultat.application_seuil;
    if (seg_recence = "R1" and seg_frequence = "F1") or 
       (seg_recence = "R1" and seg_frequence = "F2") then seg_RF = "RF1";
    else if (seg_recence = "R1" and seg_frequence = "F3") or 
            (seg_recence = "R2" and seg_frequence = "F1") or 
            (seg_recence = "R2" and seg_frequence = "F2") or 
            (seg_recence = "R3" and seg_frequence = "F1") then seg_RF = "RF2";
    else if (seg_recence = "R2" and seg_frequence = "F3") or 
            (seg_recence = "R3" and seg_frequence = "F2") or 
            (seg_recence = "R3" and seg_frequence = "F3") then seg_RF = "RF3";
    else seg_RF = "?";
run;

/* --- Étape 4 : Création des groupes RFM --- */
data resultat.segment_RFM;
    set resultat.application_seuil_RF;
    if seg_RF="RF1" and seg_montant="M1" then seg_RFM="RFM1";
    else if seg_RF="RF1" and seg_montant="M2" then seg_RFM="RFM2";
    else if seg_RF="RF1" and seg_montant="M3" then seg_RFM="RFM3";
    else if seg_RF="RF2" and seg_montant="M1" then seg_RFM="RFM4";
    else if seg_RF="RF2" and seg_montant="M2" then seg_RFM="RFM5";
    else if seg_RF="RF2" and seg_montant="M3" then seg_RFM="RFM6";
    else if seg_RF="RF3" and seg_montant="M1" then seg_RFM="RFM7";
    else if seg_RF="RF3" and seg_montant="M2" then seg_RFM="RFM8";
    else if seg_RF="RF3" and seg_montant="M3" then seg_RFM="RFM9";
    else seg_RFM = "?";
run;

/* --- Étape 5 : Ajout des nouvelles données --- */
/* 5.1. Date de la première commande */
proc sql;
    create table resultat.date_premiere_commande as
    select 
        num_client,
        min(date_sas) as date_premiere_commande format=date9.
    from donnees.commandes
    group by num_client;
quit;

/* 5.2. Statistiques sur les montants */
proc sql;
    create table resultat.stats_montants as
    select 
        num_client,
        min(montant_total_paye) as min_montant,
        mean(montant_total_paye) as mean_montant,
        max(montant_total_paye) as max_montant,
        sum(montant_total_paye) as sum_montant
    from donnees.commandes
    group by num_client;
quit;

/* 5.3. Nombre de commandes avec remise */
proc sql;
    create table resultat.commandes_avec_remise as
    select 
        num_client,
        sum(case when remise_sur_produits > 0 then 1 else 0 end) as NB_commande_V_avec_remise
    from donnees.commandes
    group by num_client;
quit;

/* 5.4. Somme des remises */
proc sql;
    create table resultat.somme_remises as
    select 
        num_client,
        sum(remise_sur_produits) as sum_montant_remise
    from donnees.commandes
    group by num_client;
quit;

/* 5.5. Somme des frais de livraison */
proc sql;
    create table resultat.somme_livraison as
    select 
        num_client,
        sum(montant_livraison) as sum_montant_livraison
    from donnees.commandes
    group by num_client;
quit;

/* --- Étape 6 : Fusionner les données dans le fichier final --- */
proc sql;
    create table resultat.segment_RFM_final as
    select 
        a.*,
        b.date_premiere_commande,
        c.min_montant, c.mean_montant, c.max_montant, c.sum_montant,
        d.NB_commande_V_avec_remise,
        e.sum_montant_remise,
        f.sum_montant_livraison
    from resultat.segment_RFM a
    left join resultat.date_premiere_commande b
        on a.num_client = b.num_client
    left join resultat.stats_montants c
        on a.num_client = c.num_client
    left join resultat.commandes_avec_remise d
        on a.num_client = d.num_client
    left join resultat.somme_remises e
        on a.num_client = e.num_client
    left join resultat.somme_livraison f
        on a.num_client = f.num_client;
quit;

/* --- Étape 7 : Exporter le fichier final --- */
proc export data=resultat.segment_RFM_final
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\segment_RFM_final.csv"
    dbms=csv
    replace;
    delimiter=";";
run;
