-- Création de la Table pour Stocker les Scores
CREATE TABLE Scores (
    ID_Utilisateur INT PRIMARY KEY,
    Score INT,
    FOREIGN KEY (ID_Utilisateur) REFERENCES Utilisateur(ID_Utilisateur)
);

-- Création de la Séquence pour les Tâches
CREATE SEQUENCE tache_seq START WITH 1 INCREMENT BY 1 NOMAXVALUE;

-- Déclencheur pour Mettre à Jour le Score à la Terminaison d'une Tâche
CREATE OR REPLACE TRIGGER TacheTermineeTrigger
AFTER UPDATE OF Statut ON Tache
FOR EACH ROW
WHEN (NEW.Statut = 'Terminée' AND OLD.Statut != 'Terminée')
BEGIN
    UPDATE Scores
    SET Score = Score + 10 -- Supposons que terminer une tâche ajoute 10 points.
    WHERE ID_Utilisateur = :NEW.ID_Utilisateur;

    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO Scores (ID_Utilisateur, Score)
        VALUES (:NEW.ID_Utilisateur, 10);
    END IF;
END;

-- Déclencheur pour Mettre à Jour le Score à l'Archivage d'une Tâche
CREATE OR REPLACE TRIGGER ArchiveTacheTrigger
AFTER INSERT ON Tache_Passee
FOR EACH ROW
BEGIN
    UPDATE Scores
    SET Score = Score + 5 -- Supposons que l'archivage d'une tâche ajoute 5 points.
    WHERE ID_Utilisateur = :NEW.ID_Utilisateur;

    IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO Scores (ID_Utilisateur, Score)
        VALUES (:NEW.ID_Utilisateur, 5);
    END IF;
END;

-- Déclencheur pour Ajuster les Tâches Périodiques
CREATE OR REPLACE TRIGGER AdjustPeriodicTasksTrigger
AFTER INSERT OR UPDATE OF date_fin, periode ON Periodicite
FOR EACH ROW
DECLARE
    v_current_date TIMESTAMP;
BEGIN
    -- Delete existing tasks for the periodicity
    DELETE FROM Taches WHERE ref_periodicite = :new.ref_periodicite;

    v_current_date := :new.date_debut;

    WHILE v_current_date <= :new.date_fin LOOP
        -- Insert a new task for each occurrence within the period
        INSERT INTO Taches (ref_tache, intitule, description, priorite, url, date_d_echeance, ref_periodicite, nom_categorie, ref_utilisateur)
        SELECT tache_seq.NEXTVAL, intitule, description, priorite, url, v_current_date, :new.ref_periodicite, nom_categorie, ref_utilisateur
        FROM Taches
        WHERE ref_periodicite = :new.ref_periodicite;

        v_current_date := v_current_date + :new.periode;
    END LOOP;
END;
