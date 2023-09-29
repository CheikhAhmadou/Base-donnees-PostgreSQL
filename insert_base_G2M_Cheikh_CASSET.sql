
----TABLE CONTRAT----

INSERT INTO master_g2m.contrats (
personne_id,
employeur_siren,
contrat_type,
contrat_duree,
conges_payes,
tickets_resto,
signature_date,
salaire_mensuel,
jours_travail_mensuels) 
VALUES 
(91, 414604645 ,'Apprentissage','[29-08-2022,28-09-2023)', 25,'true', '29-08-2022', 1877, 5);


---TABLE ETUDIANTS--
INSERT INTO master_g2m.etudiants 
(
numero_etudiant,
personne_id,
tuteur_universite_id ,
promotion_id,
responsable_clefs 
)
VALUES 
(22005922, 91, (SELECT id from master_g2m.personnes where nom ILIKE '%delaborde%'),  10, 'true');



---LA TABLE TELEPHONE---
INSERT INTO master_g2m.telephones
( 
numero,
type_telephone,
personne_id
)
( '0749974740', 'perso', 2);


---TABLE PERSONNE---
INSERT INTO master_g2m.personnes 
(
nom,
prenom,
genre,
date_naissance,
adresse_id 
)
VALUES 
('casset', 'cheikh ahmadou bamba', 'masculin',  '01-10-1996', 4);


----TABLE MAILS-----
INSERT INTO master_g2m.mails
(mail ,
type_mail,
personne_id
)
VALUES
('cheikhounacasset95@gmail.com', 'perso', 2);

---TABLE ADRESSES---
INSERT INTO master_g2m.adresses 
(numero, libelle, 
code_postal, 
ville) VALUES (37, 'rue alcide vellard', 93000, 'bobigny');

INSERT INTO master_g2m.adresses 
(numero,
libelle, 
code_postal,
ville) 
VALUES (12,'Pl de Iris', 92400,'courbevoie');

---TABLE EMPLOYEUERS---
#DEJA FAIT TABLE EMPLOYEURS
INSERT INTO master_g2m.employeurs(siren,
nom,
secteur,
statut,
effectif,
adresse_id) 
VALUES(414604645, 'saint gabain','Immobilier', 'privé',180000 ,5);