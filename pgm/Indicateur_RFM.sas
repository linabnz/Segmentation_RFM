
proc sql;
    create table resultat.indicateur_RFM as
    select
        num_client,
        min(intck('month', date_sas, "01JAN2023"d)) as recence label="Récence (mois)",
        count(distinct numero_commande) as frequence label="Fréquence (nombre de commandes)",
        sum(montant_total_paye) as montant label="Montant total payé"
    from donnees.Commandes_nettoye
    group by num_client;
quit;

proc export data=resultat.indicateur_RFM
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultat\indicateur_RFM.xlsx"
    dbms=xlsx
    replace;
run;

proc freq data = resultat.indicateur_RFM;
table recence;
run;
proc freq data = resultat.indicateur_RFM;
table frequence;
run;

proc rank data=resultat.indicateur_RFM out=Rang_montant groups=10;
    var montant; 
    ranks rang;  
run;
proc summary data=Rang_montant;
    class rang; 
    var montant; 
    output out=montant_10_RANG 
        min=montant_min 
        max=montant_max 
        mean=montant_mean; 
run;
proc print data=montant_10_RANG;
    title "Statistiques des montants par rang";
run;

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
    else if  74.40<= montant <  291.81 then seg_montant = "M2";
    else if montant >= 291.81 then seg_montant = "M3";
    else seg_montant = "?";
run;


proc print data=resultat.application_seuil(obs=10);
    title "Segments RFM par seuils";
    var num_client recence frequence montant seg_recence seg_frequence seg_montant;
run;

proc freq data=resultat.application_seuil;
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
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultat\croisement_recence_frequence.xlsx"
    dbms=xlsx
    replace;
run;

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

proc freq data = resultat.application_seuil_RF;
table seg_RF;
run;

proc freq data=resultat.application_seuil_RF;
    table seg_RF*seg_montant / out=resultat.croisement_RF_montant;
run;

proc export data=resultat.croisement_RF_montant
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultat\croisement_RF_montant.xlsx"
    dbms=xlsx
    replace;
run;


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


proc freq data=resultat.segment_RFM noprint;
    tables seg_RFM / out=resultat.freq_RFM;
run;

/* Export des résultats vers Excel */
proc export data=resultat.freq_RFM
    outfile="C:\Users\benze\OneDrive\Bureau\M2 MOSEF 2024-2025\CRM Analytics\Projet_CRM_Analytics\Segmentation_RFM\resultat\Distribution_RFM.xlsx"
    dbms=xlsx
    replace;
run;
