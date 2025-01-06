/* ======================= */
/* Étape 1 : Calcul des indicateurs RFM pour chaque client */
/* ======================= */
proc sql;
    create table resultat.indicateur_RFM as
    select
        num_client,
        /* Calcul de la récence (en mois) par rapport à janvier 2023 */
        min(intck('month', date_sas, "01JAN2023"d)) as recence label="Récence (mois)",
        /* Calcul de la fréquence : nombre distinct de commandes */
        count(distinct numero_commande) as frequence label="Fréquence (nombre de commandes)",
        /* Calcul du montant total payé */
        sum(montant_total_paye) as montant label="Montant total payé"
    from donnees.Commandes_nettoye
    group by num_client;
quit;

/* ======================= */
/* Étape 2 : Exporter les indicateurs RFM dans un fichier Excel */
/* ======================= */
proc export data=resultat.indicateur_RFM
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\indicateur_RFM.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* ======================= */
/* Étape 3 : Analyser la distribution de la récence */
/* ======================= */
proc freq data=resultat.indicateur_RFM;
    table recence;
run;

/* ======================= */
/* Étape 4 : Analyser la distribution de la fréquence */
/* ======================= */
proc freq data=resultat.indicateur_RFM;
    table frequence;
run;

/* ======================= */
/* Étape 5 : Calculer les rangs pour le montant total (groupes de 10) */
/* ======================= */
proc rank data=resultat.indicateur_RFM out=Rang_montant groups=10;
    var montant;
    ranks rang;
run;

/* ======================= */
/* Étape 6 : Calcul des statistiques (min, max, moyenne) des montants par rang */
/* ======================= */
proc summary data=Rang_montant;
    class rang;
    var montant;
    output out=montant_10_RANG 
        min=montant_min 
        max=montant_max 
        mean=montant_mean;
run;

/* ======================= */
/* Étape 7 : Affichage des statistiques des montants par rang */
/* ======================= */
proc print data=montant_10_RANG;
    title "Statistiques des montants par rang";
run;

/* ======================= */
/* Étape 8 : Appliquer des seuils pour segmenter la récence, la fréquence et le montant */
/* ======================= */
data resultat.application_seuil;
    set resultat.indicateur_RFM;

    /* Segmentation de la récence */
    if 13 < recence then seg_recence = "R1";
    else if 7 < recence <= 13 then seg_recence = "R2";
    else if recence <= 7 then seg_recence = "R3";
    else seg_recence = "?";

    /* Segmentation de la fréquence */
    if frequence = 1 then seg_frequence = "F1";
    else if 2 <= frequence <= 3 then seg_frequence = "F2";
    else if 3 < frequence then seg_frequence = "F3";
    else seg_frequence = "?";

    /* Segmentation du montant */
    if montant < 74.40 then seg_montant = "M1";
    else if  74.40 <= montant <  291.81 then seg_montant = "M2";
    else if montant >= 291.81 then seg_montant = "M3";
    else seg_montant = "?";
run;

/* ======================= */
/* Étape 9 : Afficher un échantillon des segments RFM */
/* ======================= */
proc print data=resultat.application_seuil(obs=10);
    title "Segments RFM par seuils";
    var num_client recence frequence montant seg_recence seg_frequence seg_montant;
run;

/* ======================= */
/* Étape 10 : Analyser la distribution des segments RFM */
/* ======================= */
proc freq data=resultat.application_seuil;
    tables seg_recence seg_frequence seg_montant;
run;

/* ======================= */
/* Étape 11 : Croiser les segments récence et fréquence */
/* ======================= */
proc freq data=resultat.application_seuil;
    tables seg_recence*seg_frequence / out=resultat.croisement_recence_frequence;
run;

/* ======================= */
/* Étape 12 : Afficher le croisement entre segments récence et fréquence */
/* ======================= */
proc print data=resultat.croisement_recence_frequence;
    title "Croisement entre Segments Récence et Fréquence";
run;

/* ======================= */
/* Étape 13 : Exporter le croisement récence-fréquence vers Excel */
/* ======================= */
proc export data=resultat.croisement_recence_frequence
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\croisement_recence_frequence.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* ======================= */
/* Étape 14 : Regrouper récence et fréquence en segments RF */
/* ======================= */
data resultat.application_seuil_RF;
    set resultat.application_seuil;

    /* Regroupement RF1 */
    if (seg_recence = "R1" and seg_frequence in ("F1", "F2")) then seg_RF = "RF1";

    /* Regroupement RF2 */
    else if (seg_recence = "R1" and seg_frequence = "F3")
         or (seg_recence = "R2" and seg_frequence in ("F1", "F2"))
         or (seg_recence = "R3" and seg_frequence = "F1") then seg_RF = "RF2";

    /* Regroupement RF3 */
    else if (seg_recence = "R2" and seg_frequence = "F3")
         or (seg_recence = "R3" and seg_frequence in ("F2", "F3")) then seg_RF = "RF3";

    else seg_RF = "?";
run;

/* ======================= */
/* Étape 15 : Analyser la distribution des segments RF */
/* ======================= */
proc freq data = resultat.application_seuil_RF;
    table seg_RF;
run;

/* ======================= */
/* Étape 16 : Croiser les segments RF et montant */
/* ======================= */
proc freq data=resultat.application_seuil_RF;
    table seg_RF*seg_montant / out=resultat.croisement_RF_montant;
run;

/* ======================= */
/* Étape 17 : Exporter le croisement RF-montant vers Excel */
/* ======================= */
proc export data=resultat.croisement_RF_montant
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\croisement_RF_montant.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* ======================= */
/* Étape 18 : Combiner RF et montant pour obtenir les segments RFM finaux */
/* ======================= */
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
    else seg_RFM="?";
run;

/* ======================= */
/* Étape 19 : Analyser la distribution des segments RFM finaux */
/* ======================= */
proc freq data=resultat.segment_RFM_final noprint;
    tables seg_RFM / out=resultat.freq_RFM;
run;

/* ======================= */
/* Étape 20 : Exporter les résultats finaux vers Excel */
/* ======================= */
proc export data=resultat.segment_RFM_final
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\segment_RFM_final.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

proc export data=resultat.freq_RFM
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\Resultat\Distribution_RFM.csv"
    dbms=csv
    replace;
    delimiter=";";
run;
