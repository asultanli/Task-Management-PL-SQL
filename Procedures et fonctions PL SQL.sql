-- Créer la table StopWords
CREATE TABLE StopWords (
    Word VARCHAR2(50) PRIMARY KEY
);


INSERT INTO StopWords (Word) VALUES ('le', 'la', 'de', 'et');

-- Créer la fonction GetMeaningfulWords
CREATE OR REPLACE FUNCTION GetMeaningfulWords(pText VARCHAR2) RETURN SYS.ODCIVARCHAR2LIST PIPELINED
AS
    vWord VARCHAR2(50);
BEGIN
    FOR word IN (SELECT REGEXP_SUBSTR(pText, '\w+', 1, LEVEL) AS word
                 FROM dual
                 CONNECT BY REGEXP_SUBSTR(pText, '\w+', 1, LEVEL) IS NOT NULL)
    LOOP
        IF NOT EXISTS (SELECT 1 FROM StopWords WHERE Word = word.word) THEN
            PIPE ROW (word.word);
        END IF;
    END LOOP;

    RETURN;
END GetMeaningfulWords;

-- Créer la fonction GetSimilarTasks
CREATE OR REPLACE FUNCTION GetSimilarTasks(
    pIDUtilisateur IN Utilisateur.ID_Utilisateur%TYPE,
    pN INT,
    pX INT,
    pY INT
) RETURN SYS.ODCINUMBERLIST PIPELINED
AS
BEGIN
    FOR task_id IN (
        SELECT DISTINCT a.ID_Tache
        FROM Assignation a
        JOIN Assignation b ON a.ID_Tache = b.ID_Tache AND a.ID_Utilisateur <> b.ID_Utilisateur
        JOIN Tache t ON a.ID_Tache = t.ID_Tache
        WHERE a.ID_Utilisateur = pIDUtilisateur
          AND b.ID_Utilisateur IN (
              SELECT ID_Utilisateur
              FROM Assignation
              WHERE ID_Tache IN (
                  SELECT ID_Tache
                  FROM Assignation
                  WHERE ID_Utilisateur = pIDUtilisateur
              )
              GROUP BY ID_Utilisateur
              HAVING COUNT(DISTINCT ID_Tache) >= pX
          )
        GROUP BY a.ID_Tache, t.Intitule, t.Description
        HAVING COUNT(DISTINCT b.ID_Utilisateur) >= pX
    ) LOOP
        PIPE ROW (task_id);
        EXIT WHEN pN = 0;
        pN := pN - 1;
    END LOOP;

    RETURN;
END GetSimilarTasks;

-- Ajouter la fonction CalculerPointsHebdomadaires au PL/SQL existant
CREATE OR REPLACE FUNCTION CalculerPointsHebdomadaires (pIDUtilisateur IN Utilisateur.ID_Utilisateur%TYPE)
RETURN INT
AS
    vPointsGagnes INT := 0;
    vPointsPerdus INT := 0;
BEGIN
    -- Calcul des points pour les tâches terminées
    SELECT COUNT(*)
    INTO vPointsGagnes
    FROM Tache
    WHERE ID_Tache IN (
        SELECT ID_Tache
        FROM Assignation
        WHERE ID_Utilisateur = pIDUtilisateur
    )
    AND Statut = 'Terminée'
    AND Date_Echeance BETWEEN TRUNC(CURRENT_DATE, 'IW') AND TRUNC(CURRENT_DATE, 'IW') + 6;

    -- Calcul des points pour les tâches non terminées
    SELECT COUNT(*)
    INTO vPointsPerdus
    FROM Tache
    WHERE ID_Tache IN (
        SELECT ID_Tache
        FROM Assignation
        WHERE ID_Utilisateur = pIDUtilisateur
    )
    AND Statut = 'Non Terminée'
    AND Date_Echeance BETWEEN TRUNC(CURRENT_DATE, 'IW') AND TRUNC(CURRENT_DATE, 'IW') + 6;

    -- Remplacer 10 et 5 par les points réels pour les tâches terminées et non terminées
    RETURN (vPointsGagnes * 10) - (vPointsPerdus * 5);
END CalculerPointsHebdomadaires;

-- Ajouter la procédure ArchiverTachesPassees au PL/SQL existant
CREATE OR REPLACE PROCEDURE ArchiverTachesPassees AS
BEGIN
    -- Insérer les tâches passées dans la table Tache_Passee
    INSERT INTO Tache_Passee (ID_Tache, Intitule, Description, Date_Echeance, Priorite, Statut, Lien_Externe, ID_Projet)
    SELECT ID_Tache, Intitule, Description, Date_Echeance, Priorite, Statut, Lien_Externe, ID_Projet
    FROM Tache
    WHERE Date_Echeance < CURRENT_DATE;

    -- Supprimer les tâches passées de la table Tache
    DELETE FROM Tache
    WHERE Date_Echeance < CURRENT_DATE;
END ArchiverTachesPassees;

-- Ajouter la procédure AddTaskSuggestions au PL/SQL existant
CREATE OR REPLACE PROCEDURE AddTaskSuggestions(
    pIDUtilisateur IN Utilisateur.ID_Utilisateur%TYPE,
    pNSuggestions INT,
    pXTaches INT,
    pYMotsCommuns INT
)
AS
    vTaskID INT;
BEGIN
    -- Obtenir les tâches similaires pour l'utilisateur
    FOR task_id IN (
        SELECT * FROM TABLE(GetSimilarTasks(pIDUtilisateur, pXTaches, pXTaches, pYMotsCommuns))
    ) LOOP
        -- Vérifier si la tâche suggérée n'est pas déjà attribuée à l'utilisateur
        SELECT COUNT(*)
        INTO vTaskID
        FROM Assignation
        WHERE ID_Utilisateur = pIDUtilisateur
          AND ID_Tache = task_id.COLUMN_VALUE;

        -- Si la tâche n'est pas déjà attribuée, l'ajouter aux tâches de l'utilisateur
        IF vTaskID = 0 THEN
            INSERT INTO Assignation (ID_Utilisateur, ID_Tache)
            VALUES (pIDUtilisateur, task_id.COLUMN_VALUE);

            pNSuggestions := pNSuggestions - 1;
        END IF;

        EXIT WHEN pNSuggestions = 0;
    END LOOP;
END AddTaskSuggestions;
/
