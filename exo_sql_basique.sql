-- Selectionner toutes les lignes et colonnes de la table personnes
SELECT* from master_g2m.personnes;

-- Selectionner toutes les lignes et colonnes des tables etudiants et enseignants
SELECT* from master_g2m.etudiants;
SELECT* from master_g2m.enseignants

-- Selectionner les dix premières lignes de la table cours
SELECT* from master_g2m.cours LIMIT 10


-- Selectionner les dix dernières lignes de la table entreprises, en se basant sur le siren
SELECT* FROM master_g2m.employeurs ORDER BY Siren DESC LIMIT 10;


-- Selectioner le nom et le prénom de la personne dont l'id est 30 
SELECT nom, prenom FROM master_g2m.personnes WHERE id=30;

-- Selectionner le nom et prénom des personnes de genre masculin dont le nom commence par D
SELECT nom, prenom FROM master_g2m.personnes WHERE nom ILIKE '%masculin' AND nom LIKE='%D';


-- Selectionner le nom et prénom des personnes de genre féminin nées après le 1er Juin 1980
SELECT nom, prenom FROM master_g2m.personnes WHERE nom ILIKE '%feminin' AND  date_naissance >('01-06-1980');

-- Selectionner les entreprises dont l'effectif se trouve est supérieur à 100 et inférieur à 1000
SELECT* FROM master_g2m.employeurs WHERE effectif >100 AND effectif<1000;

-- Selectionner les noms des entreprises qui travaillent dans les secteurs du conseil 
--ou de la télécommunication et dont l'effectif est inférieur à 2000
SELECT * FROM master_g2m.employeurs WHERE secteur IN ('conseil', 'telecommunication') AND effectif <2000;

-- Selectionner les noms des entreprises dont la longueur du nom est supérieur a 8
SELECT * FROM master_g2m.employeurs WHERE nom LIKE '%>8';

-- Selectionner les secteurs distinct des entreprises publiques
SELECT * FROM master_g2m.employeurs WHERE statut ILIKE '%publique';

-- Selectionner tous les cours qui ont 2 enseignants


-- Selectionner les noms des cours dont le nom commence par une voyelle


-- Selectionner les noms des cours sans doublons des cours dont le nom contient 'QGIS'
SELECT nom DISTINCT from master_g2m.cours where nom LIKE '%QGIS';

-- Selectionner les personnes nées après 1980, triées par leur nom de manière croissante


-- Calculer les moyennes d'effectif des entreprises par secteur, arrondie à l'entier supérieur


-- Calculer le nombre de personne par genre, trié par order décroissant de nombre

