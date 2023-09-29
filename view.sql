CREATE OR REPLACE VIEW master_g2m.completion_infos_etudiants_m2g2m
AS SELECT jointure_tables_g2m.prenom,
    jointure_tables_g2m.nom,
        CASE
            WHEN jointure_tables_g2m.probleme IS NULL THEN true
            ELSE false
        END AS completion_donnees,
    jointure_tables_g2m.probleme
   FROM ( SELECT a.prenom,
            a.nom,
                CASE
                    WHEN b.promotion_id <> 10 THEN 'Mauvais numero de promotion renseigné'::text
                    WHEN b.numero_etudiant IS NULL THEN 'Information non intégrée dans la table "etudiants"'::text
                    WHEN c.id IS NULL THEN 'Information non intégrée dans la table "adresses"'::text
                    WHEN d.mail IS NULL THEN 'Information non intégrée dans la table "mail"'::text
                    WHEN e.telephone IS NULL THEN 'Information non intégrée dans la table "telephones"'::text
                    WHEN f.id IS NULL THEN 'Tuteur Université non renseigné'::text
                    WHEN g.id IS NULL THEN 'Information non intégrée dans la table "contrat"'::text
                    ELSE NULL::text
                END AS probleme
           FROM master_g2m.personnes a
             LEFT JOIN master_g2m.etudiants b ON a.id = b.personne_id
             LEFT JOIN master_g2m.adresses c ON a.adresse_id = c.id
             LEFT JOIN ( SELECT mails.personne_id,
                    array_agg((mails.type_mail || ' : '::text) || mails.mail::text) AS mail
                   FROM master_g2m.mails
                  GROUP BY mails.personne_id) d ON a.id = d.personne_id
             LEFT JOIN ( SELECT telephones.personne_id,
                    array_agg((telephones.type_telephone || ' : '::text) || telephones.numero) AS telephone
                   FROM master_g2m.telephones
                  GROUP BY telephones.personne_id) e ON a.id = e.personne_id
             LEFT JOIN master_g2m.enseignants f ON b.tuteur_universite_id = f.personne_id
             LEFT JOIN master_g2m.personnes g ON f.personne_id = g.id
             LEFT JOIN master_g2m.contrats h ON a.id = h.personne_id
             LEFT JOIN master_g2m.employeurs i ON h.employeur_siren = i.siren
             LEFT JOIN master_g2m.adresses j ON i.adresse_id = j.id
          WHERE b.promotion_id = 10 OR (a.nom = ANY (ARRAY['Diop'::text, 'Haddouch'::text, 'Julien'::text]))
          ORDER BY a.nom) jointure_tables_g2m;