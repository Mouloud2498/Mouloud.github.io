# 🐳📦 Analyse Big Data avec Docker & Hadoop (MapReduce Streaming)

## 1) Contexte
Dans un contexte e-commerce, les données de ventes peuvent devenir volumineuses.  
L’objectif de ce projet est de montrer comment traiter un **gros fichier CSV** avec un pipeline **Hadoop MapReduce** exécuté dans **Docker**, en utilisant **Hadoop Streaming** (mappers/reducers Python).

🎯 **Objectif** : produire des indicateurs fiables et reproductibles à partir d’un dataset de ventes :  
- **CA net par pays et par mois**
- **Top 10 produits** (par CA net)
- **Taux de retour**
- **Répartition des paiements**

---

## 2) Problème à résoudre (Business Problem)
On dispose d’un flux de transactions contenant :
- pays, date, produit, quantité, prix
- mode de paiement
- statut de commande (retour / remboursement / livraison)

✅ On veut répondre à des questions métier :
1. Quel est le **CA net** (en tenant compte des retours) par **pays** et **mois** ?
2. Quels sont les **10 produits** les plus performants ?
3. Quel est le **taux de retour** global ?
4. Quels sont les **modes de paiement** les plus utilisés ?

---

## 3) Données
### Génération des données
Le projet inclut un script qui génère un fichier de ventes volumineux (CSV) pour simuler un contexte Big Data :

- `generate_sales_big.py` → génère `sales_big.csv` (objectif ~260 MB)

> Si tu utilises un fichier réel, indique-le ici.

### Schéma de données (colonnes principales)
Exemples de colonnes utilisées :
- `country`, `date`, `product`, `quantity`, `price`
- `payment_method`
- `status` (ex: delivered / returned / refunded)

---

## 4) Démarche (Processus)
### A) Préparation
- Génération du dataset volumineux (CSV)
- Démarrage d’un environnement Hadoop via Docker (HDFS + YARN)

### B) Ingestion dans HDFS
- Création d’un répertoire HDFS
- Upload du fichier CSV dans HDFS

### C) Traitements MapReduce (Hadoop Streaming)
Chaque indicateur est calculé via un couple **mapper/reducer** Python :

1) **CA net par pays et par mois**
- Mapper : extrait la clé (pays, mois) et la valeur (montant, statut)
- Reducer : agrège et calcule le CA net (en gérant retours/remboursements)

2) **Top 10 produits (CA net)**
- Mapper : (produit → montant)
- Reducer : somme par produit puis tri pour conserver le top 10

3) **Taux de retour**
- Mapper : compte total commandes et retours
- Reducer : calcule % retour

4) **Répartition des paiements**
- Mapper : (mode_paiement → 1)
- Reducer : agrège et calcule la distribution

### D) Export des résultats
Les résultats sont récupérés depuis HDFS (ou affichés) dans des fichiers de sortie.

---

## 5) Hypothèses (Assumptions)
- Le dataset suit un format CSV cohérent (séparateur, colonnes, types)
- Les statuts de commande sont corrects (ex: returned/refunded)
- Le CA net est calculé comme :  
  **CA net = ventes - retours/remboursements** (selon la règle définie)
- Les données sont suffisamment grandes pour justifier l’approche MapReduce

---

## 6) KPI / Mesures d’impact
Ce projet met en avant des KPI “métier” et “techniques” :

### KPI métier
- **CA net** par pays / mois
- **Top 10 produits** par CA net
- **Taux de retour (%)**
- **Répartition des paiements (%)**

### KPI techniques (qualité & performance)
- Volume du dataset (ex : ~260MB)
- Temps d’exécution des jobs (si mesuré)
- Reproductibilité (mêmes résultats avec les mêmes données)

---

## 7) Résultats (exemples)
> Ajoute des captures dans `assets/` (recommandé)

- `assets/hdfs_upload.png` (upload HDFS)
- `assets/job_run.png` (exécution des jobs)
- `assets/output_sample.png` (extrait des résultats)

Exemple d’affichage :

![Upload HDFS](assets/hdfs_upload.png)
![Exécution Job](assets/job_run.png)
![Résultats](assets/output_sample.png)

---


