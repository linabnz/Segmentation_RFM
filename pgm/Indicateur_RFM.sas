data donnees.commandes;
    set donnees.commandes;

    /* Remplacement des mois fran�ais par des mois reconnus par SAS */
    date_modifiee = tranwrd(date, "janv", "jan");
    date_modifiee = tranwrd(date_modifiee, "f�vr", "feb");
    date_modifiee = tranwrd(date_modifiee, "mars", "mar");
    date_modifiee = tranwrd(date_modifiee, "avr", "apr");
    date_modifiee = tranwrd(date_modifiee, "mai", "may");
    date_modifiee = tranwrd(date_modifiee, "juin", "jun");
    date_modifiee = tranwrd(date_modifiee, "juil", "jul");
    date_modifiee = tranwrd(date_modifiee, "ao�t", "aug");
    date_modifiee = tranwrd(date_modifiee, "sept", "sep");
    date_modifiee = tranwrd(date_modifiee, "oct", "oct");
    date_modifiee = tranwrd(date_modifiee, "nov", "nov");
    date_modifiee = tranwrd(date_modifiee, "d�c", "dec");

    /* Conversion de texte modifi� en format Date SAS */
    date_sas = input(date_modifiee, date9.);
    format date_sas date9.; /* Appliquer le format de date SAS */
run;

proc print data=donnees.commandes(obs=10);
    var date date_modifiee date_sas;
run;

proc sql;
    create table resultat.indicateur_RFM as
    select
        num_client,
        min(intck('month', date_sas, "01jan2024"d)) as recence,
        count(distinct numero_commande) as frequence,
        sum(montant_total_paye) as montant
    from donnees.commandes
    group by num_client;
quit;
