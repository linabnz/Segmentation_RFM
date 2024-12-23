
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

proc freq data = resultat.indicateur_RFM;
table recence;
run;
proc freq data = resultat.indicateur_RFM;
table frequence;
run;

/* Étape 1 : Créer des groupes basés sur la variable montant */
proc rank data=resultat.indicateur_RFM out=Rang_montant groups=10;
    var montant; /* Variable utilisée pour le classement */
    ranks rang;  /* Nouvelle variable contenant le rang */
run;

/* Étape 2 : Résumer les statistiques pour chaque groupe */
proc summary data=Rang_montant;
    class rang; /* Classer les observations par groupe */
    var montant; /* Variable à analyser */
    output out=montant_10_RANG /* Nom de la table de sortie */
        min=montant_min /* Valeur minimale pour chaque groupe */
        max=montant_max /* Valeur maximale pour chaque groupe */
        mean=montant_mean; /* Moyenne pour chaque groupe */
run;

/* Étape 3 : Afficher les résultats */
proc print data=montant_10_RANG;
    title "Statistiques des montants par rang";
run;

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

/* Afficher un aperçu des données */
proc print data=resultat.application_seuil(obs=10);
    title "Segments RFM par seuils";
    var num_client recence frequence montant seg_recence seg_frequence seg_montant;
run;

proc freq data=resultat.application_seuil;
    tables seg_recence seg_frequence seg_montant;
run;


/* Vérification des répartitions des segments */
proc freq data=application_seuil;
    tables seg_recence seg_frequence seg_montant;
run;

proc freq data=resultat.application_seuil;
    tables seg_recence*seg_frequence / out=resultat.croisement_recence_frequence;
run;

/* Affichage du résultat du croisement */
proc print data=resultat.croisement_recence_frequence;
    title "Croisement entre Segments Récence et Fréquence";
run;

proc export data=resultat.croisement_recence_frequence
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultats\croisement_recence_frequence.xlsx"
    dbms=xlsx
    replace;
run;

data resultat.application_seuil_RF;
    set resultat.application_seuil;

    /* RF1 : Récence R1 avec Fréquence F1 ou F2 */
    if (seg_recence = "R1" and seg_frequence = "F1") or 
       (seg_recence = "R1" and seg_frequence = "F2") then seg_RF = "RF1";

    /* RF2 : Combinaisons variées */
    else if (seg_recence = "R1" and seg_frequence = "F3") or 
            (seg_recence = "R2" and seg_frequence = "F1") or 
            (seg_recence = "R2" and seg_frequence = "F2") or 
            (seg_recence = "R3" and seg_frequence = "F1") then seg_RF = "RF2";

    /* RF3 : Récence R2 ou R3 avec Fréquence F2 ou F3 */
    else if (seg_recence = "R2" and seg_frequence = "F3") or 
            (seg_recence = "R3" and seg_frequence = "F2") or 
            (seg_recence = "R3" and seg_frequence = "F3") then seg_RF = "RF3";

    /* Autres */
    else seg_RF = "?";
run;

proc freq data = resultat.application_seuil_RF;
table seg_RF;
run;

proc freq data=resultat.application_seuil_RF;
    table seg_RF*seg_montant / out=resultat.croisement_RF_montant;
run;

proc export data=resultat.croisement_RF_montant
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultats\croisement_RF_montant.xlsx"
    dbms=xlsx
    replace;
run;


data donnees.segment_RFM;
    set resultat.application_seuil_RF;

    /* Combinaisons RF et Montant pour créer les 9 groupes */
    if seg_RF="RF1" and seg_montant="M1" then seg_RFM="RFM1";
    else if seg_RF="RF1" and seg_montant="M2" then seg_RFM="RFM2";
    else if seg_RF="RF1" and seg_montant="M3" then seg_RFM="RFM3";
    else if seg_RF="RF2" and seg_montant="M1" then seg_RFM="RFM4";
    else if seg_RF="RF2" and seg_montant="M2" then seg_RFM="RFM5";
    else if seg_RF="RF2" and seg_montant="M3" then seg_RFM="RFM6";
    else if seg_RF="RF3" and seg_montant="M1" then seg_RFM="RFM7";
    else if seg_RF="RF3" and seg_montant="M2" then seg_RFM="RFM8";
    else if seg_RF="RF3" and seg_montant="M3" then seg_RFM="RFM9";
    else seg_RFM="?"; /* Cas par défaut pour les valeurs inattendues */

run;

/* Vérification des résultats */
proc freq data=donnees.segment_RFM;
    tables seg_RFM;
    title "Distribution des Groupes RFM";
run;
