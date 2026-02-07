#!/bin/bash
 
# =========================================================
# CONFIGURATION
# =========================================================
 
MASTER_CONTAINER="hadoop-master" 
LOCAL_DATA_FILE="sales_ua2.csv"
 
# Chemins HDFS
HDFS_INPUT_DIR="/user/root/input"
HDFS_OUTPUT_ROOT="/user/root/output"
 
# Dossiers locaux pour les livrables
LOCAL_OUTPUT_BASE="./livrables_UA2"
 
SUCCESS_COUNT=0
TOTAL_JOBS=4
 
# Assurez-vous que les scripts Python ont les droits d'exécution
echo "Attribution des droits d'exécution aux scripts Python..."
chmod +x mapper_top10.py
chmod +x reducer_top10.py
chmod +x mapper_retours.py
chmod +x reducer_retours.py
chmod +x mapper_paiements.py
chmod +x reducer_paiements.py
chmod +x mapper_ca.py
chmod +x reducer_ca.py
 
# =========================================================
# FONCTION DE NETTOYAGE/FORMATAGE DES DONNÉES DE SORTIE
# =========================================================
 
# Fonction qui nettoie la sortie brute (part-00000) et la réécrit dans un format propre
# Arguments: $1=Nom du Job (output_ca), $2=Noms des Colonnes (Python list style)
format_output() {
    JOB_NAME=$1
    COL_NAMES=$2
    LOCAL_OUTPUT_DIR="$LOCAL_OUTPUT_BASE/$JOB_NAME"
    INPUT_FILE="$LOCAL_OUTPUT_DIR/part-00000"
    OUTPUT_FILE="$LOCAL_OUTPUT_DIR/${JOB_NAME}_clean.txt"
 
    # Vérification que le fichier brut existe
    if [ ! -f "$INPUT_FILE" ]; then
        echo "   -> AVERTISSEMENT: Fichier brut $INPUT_FILE non trouvé pour formatage."
        return
    fi
 
    # Code Python pour le nettoyage des données (Heredoc)
    python3 << EOF
import pandas as pd
import sys
import os
 
JOB_NAME = "$JOB_NAME"
COL_NAMES = $COL_NAMES
INPUT_FILE = "$INPUT_FILE"
OUTPUT_FILE = "$OUTPUT_FILE"
 
try:
    # 1. Lecture du fichier MapReduce brut (séparateur par tabulation)
    df = pd.read_csv(
        INPUT_FILE, 
        sep='\t', 
        header=None, 
        names=COL_NAMES, 
        on_bad_lines='skip', 
        engine='python', 
        encoding='utf-8', 
        skipinitialspace=True
    )
    # 2. Nettoyage et typage de la colonne de valeur (la dernière)
    value_col = COL_NAMES[-1]
    df[value_col] = pd.to_numeric(df[value_col], errors='coerce')
    df = df.dropna(subset=[value_col])
    # Si c'est le Livrable 5.1 (CA Pays/Mois), on corrige l'ordre si nécessaire
    if JOB_NAME == "output_ca":
        # Le Reducer émet : ANNEE-MOIS \t PAYS \t CA_NET (on s'assure qu'ils sont bien séparés)
        # Aucune action supplémentaire n'est nécessaire car le reducer doit déjà séparer en 3 colonnes.
        pass
 
    # 3. Écriture du fichier nettoyé (sans index ni header)
    df.to_csv(OUTPUT_FILE, sep='\t', header=False, index=False)
    print(f"Nettoyage et formatage du fichier {JOB_NAME} terminés avec succès dans {OUTPUT_FILE}.")
 
except Exception as e:
    sys.stderr.write(f"ERREUR PANDAS lors du formatage du fichier {JOB_NAME}: {e}\n")
 
EOF
}
 
 
# Fonction de vérification après job
execute_and_check_job() {
    JOB_NAME=$1
    MAPPER_SCRIPT=$2
    REDUCER_SCRIPT=$3
    REDUCES=$4
    COL_NAMES_PYTHON=$5
    LOCAL_OUTPUT_DIR="$LOCAL_OUTPUT_BASE/$JOB_NAME"
    HDFS_OUTPUT_DIR="$HDFS_OUTPUT_ROOT/$JOB_NAME"
    echo -e "\n--- EXÉCUTION DU JOB '$JOB_NAME' ---"
    mkdir -p "$LOCAL_OUTPUT_DIR"
    hdfs dfs -rm -r -f "$HDFS_OUTPUT_DIR"
 
    hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
        -D mapreduce.job.name="$JOB_NAME" \
        -D mapreduce.job.reduces=$REDUCES \
        -files $MAPPER_SCRIPT,$REDUCER_SCRIPT \
        -mapper "python3 $MAPPER_SCRIPT" \
        -reducer "python3 $REDUCER_SCRIPT" \
        -input "$HDFS_INPUT_DIR/*" \
        -output "$HDFS_OUTPUT_DIR"
 
    # Vérification et formatage
    if hdfs dfs -test -f "$HDFS_OUTPUT_DIR/_SUCCESS"; then
        echo "✅ SUCCÈS : Job '$JOB_NAME' terminé."
        # 1. Récupération du fichier brut (part-00000)
        hdfs dfs -get "$HDFS_OUTPUT_DIR/part-00000" "$LOCAL_OUTPUT_DIR/$JOB_NAME""_brut.txt"
        # 2. Nettoyage et formatage avec le script Python embarqué
        format_output $JOB_NAME "$COL_NAMES_PYTHON"
        # 3. Affichage de l'aperçu du fichier BRUT (pour le débogage)
        echo "Aperçu du Fichier BRUT (Débogage) :"
        cat "$LOCAL_OUTPUT_DIR/$JOB_NAME""_brut.txt" 2>/dev/null | head -n 10
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ ÉCHEC : Job '$JOB_NAME' n'a pas produit de fichier _SUCCESS."
    fi
}
 
 
# =========================================================
# ÉTAPE 1 : PRÉPARATION (HDFS)
# =========================================================
 
echo "--- ÉTAPE 1 : PRÉPARATION HDFS ---"
 
hdfs dfs -rm -r -f "$HDFS_INPUT_DIR" > /dev/null 2>&1
hdfs dfs -mkdir -p "$HDFS_INPUT_DIR"
 
echo "Chargement du fichier $LOCAL_DATA_FILE vers $HDFS_INPUT_DIR/..."
# Le fichier est supposé être dans /root du conteneur (d'où l'exécution de hdfs dfs -put)
hdfs dfs -put -f "$LOCAL_DATA_FILE" "$HDFS_INPUT_DIR/"
 
 
# =========================================================
# EXÉCUTION DES JOBS (2, 3, 4, 5)
# =========================================================
 
# Job 5.1: CA par Pays et Mois
execute_and_check_job "output_ca" "mapper_ca.py" "reducer_ca.py" 1 "['Mois', 'Pays', 'CA Net']"
 
# Job 5.2: Top 10 Produits
execute_and_check_job "output_top10" "mapper_top10.py" "reducer_top10.py" 1 "['Produit ID', 'CA Net']"
 
# Job 5.3: Taux de Retour
execute_and_check_job "output_retours" "mapper_retours.py" "reducer_retours.py" 1 "['Metric', 'Value']"
 
# Job 5.4: Répartition Paiements
execute_and_check_job "output_payments" "mapper_payments.py" "reducer_payments.py" 1 "['Mode de Paiement', 'CA Net']"
 
 
 
echo -e "\n--- FIN DU SCRIPT run.sh ---"