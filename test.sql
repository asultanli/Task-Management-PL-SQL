-- Tester une Procédure (Exemple : AjouterNouvelleTache)
BEGIN
    -- Remplacez les valeurs ci-dessous par des valeurs de test valides
    AjouterNouvelleTache('Tâche Test', 'Description de test', SYSDATE + 7, 3, 1);
END;
/

-- Tester une Fonction (Exemple : CalculerScoreTotal)
DECLARE
    vScoreTotal INT;
BEGIN
    -- Remplacez '1' par l'ID d'un utilisateur de test
    vScoreTotal := CalculerScoreTotal(1);
    DBMS_OUTPUT.PUT_LINE('Score total: ' || vScoreTotal);
END;
/

-- Tester une nouvelle Fonction (Exemple : GetMeaningfulWords)
DECLARE
    vText VARCHAR2(200) := 'This is a test sentence with common stop words like le and de.';
    vMeaningfulWords SYS.ODCIVARCHAR2LIST;
BEGIN
    vMeaningfulWords := GetMeaningfulWords(vText);
    FOR i IN 1..vMeaningfulWords.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Meaningful Word: ' || vMeaningfulWords(i));
    END LOOP;
END;
/

-- Tester une nouvelle Procédure (Exemple : ArchiverTachesPassees)
BEGIN
    ArchiverTachesPassees;
END;
/

-- Tester une nouvelle Procédure (Exemple : AddTaskSuggestions)
BEGIN
    -- Remplacez '1' par l'ID d'un utilisateur de test
    AddTaskSuggestions(1, 3, 2, 1);
END;
/

-- Tester les Déclencheurs
INSERT INTO Utilisateur (ID_Utilisateur, Nom, Prenom, Adresse, Date_Naissance, Login, MotDePasse, Score, Niveau) VALUES (1, 'Test', 'Utilisateur', '123 rue de Test', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'test01', 'password', 0, 1);
INSERT INTO Tache (ID_Tache, Intitule, Description, Date_Echeance, Priorite, Statut, ID_Projet) VALUES (1, 'Tâche Test', 'Description Test', SYSDATE + 1, 3, 'Non Terminée', 1);

-- Mettre à jour le statut pour déclencher TacheTermineeTrigger
UPDATE Tache SET Statut = 'Terminée' WHERE ID_Tache = 1;

-- Vérifier si le score a été mis à jour
SELECT Score FROM Utilisateur WHERE ID_Utilisateur = 1;
