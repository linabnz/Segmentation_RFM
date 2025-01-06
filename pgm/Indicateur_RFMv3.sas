/* �tape 1 : Calcul des indicateurs RFM pour chaque client */
proc sql;
    create table resultat.indicateur_RFM as
    select
        num_client,
        /* Calcul de la r�cence (en mois) par rapport � janvier 2023 */
        min(intck('month', date_sas, "01JAN2023"d)) as recence label="R�cence (mois)",
        /* Calcul de la fr�quence : nombre distinct de commandes */
        count(distinct numero_commande) as frequence label="Fr�quence (nombre de commandes)",
        /* Calcul du montant total pay� */
        sum(montant_total_paye) as montant label="Montant total pay�"
    from donnees.Commandes_nettoye
    group by num_client;
quit;

/* �tape 2 : Exporter les indicateurs RFM dans un fichier Excel */
proc export data=resultat.indicateur_RFM
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\indicateur_RFM.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* �tape 3 : Analyser la distribution de la r�cence */
proc freq data=resultat.indicateur_RFM;
    table recence;
run;

/* �tape 4 : Analyser la distribution de la fr�quence */
proc freq data=resultat.indicateur_RFM;
    table frequence;
run;

/* �tape 5 : Calculer les rangs pour le montant total (groupes de 10) */
proc rank data=resultat.indicateur_RFM out=Rang_montant groups=10;
    var montant; 
    ranks rang;  
run;

/* �tape 6 : Calcul des statistiques (min, max, moyenne) des montants par rang */
proc summary data=Rang_montant;
    class rang; 
    var montant; 
    output out=montant_10_RANG 
        min=montant_min 
        max=montant_max 
        mean=montant_mean; 
run;

/* �tape 7 : Affichage des statistiques des montants par rang */
proc print data=montant_10_RANG;
    title "Statistiques des montants par rang";
run;

/* �tape 8 : Appliquer des seuils pour segmenter la r�cence, la fr�quence et le montant */
data resultat.application_seuil;
    set resultat.indicateur_RFM;

    /* Segmentation de la r�cence */
    if 13 < recence then seg_recence = "R1";
    else if 7 < recence <= 13 then seg_recence = "R2";
    else if recence <= 7 then seg_recence = "R3";
    else seg_recence = "?";

    /* Segmentation de la fr�quence */
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

/* �tape 9 : Afficher un �chantillon des segments RFM */
proc print data=resultat.application_seuil(obs=10);
    title "Segments RFM par seuils";
    var num_client recence frequence montant seg_recence seg_frequence seg_montant;
run;

/* �tape 10 : Analyser la distribution des segments RFM */
proc freq data=resultat.application_seuil;
    tables seg_recence seg_frequence seg_montant;
run;

/* �tape 11 : Croiser les segments r�cence et fr�quence */
proc freq data=resultat.application_seuil;
    tables seg_recence*seg_frequence / out=resultat.croisement_recence_frequence;
run;

/* �tape 12 : Afficher le croisement entre segments r�cence et fr�quence */
proc print data=resultat.croisement_recence_frequence;
    title "Croisement entre Segments R�cence et Fr�quence";
run;

/* �tape 13 : Exporter le croisement r�cence-fr�quence vers Excel */
proc export data=resultat.croisement_recence_frequence
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\croisement_recence_frequence.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* �tape 14 : Regrouper r�cence et fr�quence en segments RF */
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

/* �tape 15 : Analyser la distribution des segments RF */
proc freq data = resultat.application_seuil_RF;
    table seg_RF;
run;

/* �tape 16 : Croiser les segments RF et montant */
proc freq data=resultat.application_seuil_RF;
    table seg_RF*seg_montant / out=resultat.croisement_RF_montant;
run;

/* �tape 17 : Exporter le croisement RF-montant vers Excel */
proc export data=resultat.croisement_RF_montant
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\croisement_RF_montant.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* �tape 18 : Combiner RF et montant pour obtenir les segments RFM finaux */
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


/* �tape 18 : Combiner RF et montant pour obtenir les segments RFM finaux */
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

/* --- �tape 5 : Ajout des nouvelles donn�es --- */
/* 5.1. Date de la premi�re commande */
proc sql;
    create table resultat.date_premiere_commande as
    select 
        num_client,
        min(date_sas) as date_premiere_commande format=date9.
    from donnees.commandes_nettoye
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
    from donnees.commandes_nettoye
    group by num_client;
quit;

/* 5.3. Nombre de commandes avec remise */
proc sql;
    create table resultat.commandes_avec_remise as
    select 
        num_client,
        sum(case when remise_sur_produits > 0 then 1 else 0 end) as NB_commande_V_avec_remise
    from donnees.commandes_nettoye
    group by num_client;
quit;

/* 5.4. Somme des remises */
proc sql;
    create table resultat.somme_remises as
    select 
        num_client,
        sum(remise_sur_produits) as sum_montant_remise
    from donnees.commandes_nettoye
    group by num_client;
quit;

/* 5.5. Somme des frais de livraison */
proc sql;
    create table resultat.somme_livraison as
    select 
        num_client,
        sum(montant_livraison) as sum_montant_livraison
    from donnees.commandes_nettoye
    group by num_client;
quit;

/* --- �tape 6 : Fusionner les donn�es dans le fichier final --- */
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

/* �tape 19 : Analyser la distribution des segments RFM finaux */
proc freq data=resultat.segment_RFM_final noprint;
    tables seg_RFM / out=resultat.freq_RFM;
run;

proc export data=resultat.segment_RFM_final
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\segment_RFM_final.csv"
    dbms=csv
    replace;
    delimiter=";";
run;

/* �tape 20 : Exporter la distribution des segments RFM vers Excel */
proc export data=resultat.freq_RFM
    outfile="C:\Users\chemm\Desktop\cours\MOSEF\SAS\Projet\2-Projet_segmentation\2-Projet_segmentation\Resultat\Distribution_RFM.csv"
    dbms=csv
    replace;
    delimiter=";";
run;
