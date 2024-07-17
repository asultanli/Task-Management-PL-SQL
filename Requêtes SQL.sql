-- Les listes de tâches ayant au moins 5 tâches et appartenant à des utilisateurs habitant en France.

SELECT P.ID_Projet, P.Nom AS NomProjet, U.ID_Utilisateur, U.Nom, U.Prénom, COUNT(T.ID_Tache) AS NombreDeTaches
FROM Projet P
JOIN Utilisateur U ON P.ID_Utilisateur = U.ID_Utilisateur
JOIN Tache T ON P.ID_Projet = T.ID_Projet
WHERE U.Adresse LIKE '%France%'
GROUP BY P.ID_Projet, U.ID_Utilisateur
HAVING COUNT(T.ID_Tache) >= 5;

CREATE INDEX idx_assignation_idutilisateur ON Assignation(ID_Utilisateur);
CREATE INDEX idx_tache_idtache ON Tache(ID_Tache);

-- Les programmes de tâche ayant le plus de points positifs (somme des points) associés aux tâches terminées.

SELECT P.ID_Projet, P.Nom AS NomProjet, SUM(T.Points) AS TotalPoints
FROM Projet P
JOIN Tache T ON P.ID_Projet = T.ID_Projet
WHERE T.Statut = 'Terminée' AND T.Points > 0
GROUP BY P.ID_Projet
ORDER BY SUM(T.Points) DESC;

CREATE INDEX idx_tache_idprojet ON Tache(ID_Projet);
CREATE INDEX idx_projet_idprojet ON Projet(ID_Projet);

-- Pour chaque utilisateur, son login, son nom, son prénom, son adresse, son nombre de tâches total (périodique et non-périodique) et son nombre de tâches périodiques total.

SELECT 
    U.Login,
    U.Nom,
    U.Prénom,
    U.Adresse,
    COUNT(T.ID_Tache) AS NombreDeTachesTotal,
    COUNT(CASE WHEN T.Periodicite IS NOT NULL THEN 1 END) AS NombreDeTachesPeriodiques
FROM 
    Utilisateur U
LEFT JOIN 
    Assignation A ON U.ID_Utilisateur = A.ID_Utilisateur
LEFT JOIN 
    Tache T ON A.ID_Tache = T.ID_Tache
GROUP BY 
    U.Login, U.Nom, U.Prénom, U.Adresse;

CREATE INDEX idx_tache_idprojet_points ON Tache(ID_Projet, Points);
CREATE INDEX idx_tache_statut ON Tache(Statut);

--Pour chaque tâche, le nombre de dépendance à effectuer avant que la tâche puisse être réalisée.

SELECT 
    T.ID_Tache,
    T.Intitulé,
    COUNT(D.ID_Tache_Dependante) AS NombreDeDependances
FROM 
    Tache T
LEFT JOIN 
    Dependance D ON T.ID_Tache = D.ID_Tache_Dependante
GROUP BY 
    T.ID_Tache, T.Intitulé;

CREATE INDEX idx_dependance_idtachedependante ON Dependance(ID_Tache_Dependante);

-- Les 10 utilisateurs ayant gagné le plus de points sur leur score au cours de la semaine courante.

SELECT 
    U.ID_Utilisateur,
    U.Login,
    U.Nom,
    U.Prénom,
    SUM(HS.PointsGagnes) AS PointsGagnesCetteSemaine
FROM 
    Utilisateur U
JOIN 
    HistoriqueScores HS ON U.ID_Utilisateur = HS.ID_Utilisateur
WHERE 
    HS.DateMiseAJour >= DATE_TRUNC('week', CURRENT_DATE)
    AND HS.DateMiseAJour < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week'
GROUP BY 
    U.ID_Utilisateur
ORDER BY 
    PointsGagnesCetteSemaine DESC
LIMIT 10;

CREATE INDEX idx_historiquescores_idutilisateur_datemiseajour ON HistoriqueScores(ID_Utilisateur, DateMiseAJour);
CREATE INDEX idx_historiquescores_pointsgagnes ON HistoriqueScores(PointsGagnes);
