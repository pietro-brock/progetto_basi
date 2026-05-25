#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dependencies/include/libpq-fe.h"

#define PG_HOST "127.0.0.1"
#define PG_USER "postgres"
#define PG_DB   "biblioshop"
#define PG_PASS " "
#define PG_PORT "5432"
#define TRUE  1
#define FALSE 0
//#define DEBUG

//UTILITÀ DI INPUT

/*
 * Legge un intero da stdin mostrando prima il messaggio.
 * Usa fgets + sscanf per una gestione degli errori robusta:
 * - ignora caratteri extra sulla riga
 * - ripete la richiesta in caso di input non numerico
*/
int read_int_from_stdin(const char* message) {

    char input[100];
    int  result;
    char garbage;

    while (TRUE) {
        printf("%s", message);

        if (fgets(input, sizeof(input), stdin) == NULL) {
            fprintf(stderr, "Errore nella lettura dell'input.\n");
            exit(1);
        }
        input[strcspn(input, "\n")] = 0;

        if (sscanf(input, " %d %c", &result, &garbage) == 1) {
            return result;
        } else {
            printf("Inserire solamente valori numerici.\n");
        }
    }
}

// Legge una stringa da stdin in un buffer già allocato dal chiamante.
// Tronca l'input se supera size-1 caratteri.
char* read_string_from_stdin(char* input, int size, const char* message) {

    printf("%s", message);

    if (fgets(input, size, stdin) == NULL) {
        fprintf(stderr, "Errore nella lettura dell'input.\n");
        exit(1);
    }

    if (input[strlen(input) - 1] != '\n') {
        printf("Input troppo lungo: i caratteri in eccesso sono stati eliminati.\n");
    } else {
        input[strcspn(input, "\n")] = 0;
    }

    return input;
}

//CONNESSIONE AL DATABASE

/*
 * Apre una connessione a PostgreSQL con i parametri forniti.
 * Termina il programma in caso di errore.
 * Reminder: hostaddr richiede un IP numerico (non alias come "localhost").
 */
PGconn* connect_to_DB(const char* user, const char* password,
                      const char* db_name, const char* host_name,
                      const char* port) {

    char connection_info[250];
    sprintf(connection_info,
            "user=%s password=%s dbname=%s hostaddr=%s port=%s",
            user, password, db_name, host_name, port);

    PGconn* connection = PQconnectdb(connection_info);

    if (PQstatus(connection) != CONNECTION_OK) {
        printf("\nErrore di connessione: %s\n", PQerrorMessage(connection));
        PQfinish(connection);
        exit(1);
    }

    printf("Connessione al DB avvenuta con successo.\n");
    return connection;
}

//ESECUZIONE QUERY

/* Esegue una query senza parametri. Termina in caso di errore. */
PGresult* execute_query(PGconn* connection, const char* query) {

    PGresult* result = PQexec(connection, query);

    if (PQresultStatus(result) != PGRES_TUPLES_OK) {
        printf("\nErrore nell'esecuzione della query: %s\n",
               PQerrorMessage(connection));
        PQclear(result);
        exit(1);
    }

    return result;
}

/* Esegue una query parametrizzata con PQexecParams. Termina in caso di errore. */
PGresult* execute_parametric_query(PGconn* connection, const char* query,
                                   int num_parameters,
                                   const char* const* parameters) {

    PGresult* result = PQexecParams(connection, query, num_parameters,
                                    NULL, parameters, NULL, NULL, 0);

    if (PQresultStatus(result) != PGRES_TUPLES_OK) {
        printf("\nErrore nell'esecuzione della query parametrica: %s\n",
               PQerrorMessage(connection));
        PQclear(result);
        exit(1);
    }

    return result;
}

//MENU

void print_query_list() {

    printf("\n");
    printf("        BiblioShop Online: Menu Query\n");
    printf("\n");
    printf("  1: Top N clienti ordinati per spesa totale.\n");
    printf("     (Parametro: numero risultati da visualizzare)\n");
    printf("\n");
    printf("  2: Fruitori con piu di N prenotazioni.\n");
    printf("     (Parametro: soglia minima di prenotazioni)\n");
    printf("\n");
    printf("  3: Top N corrieri per numero spedizioni e totale fatturato.\n");
    printf("     (Parametro: numero risultati da visualizzare)\n");
    printf("\n");
    printf("  4: Top N contenuti digitali piu prenotati (Libri e DVD).\n");
    printf("     (Parametro: numero risultati da visualizzare)\n");
    printf("\n");
    printf("  5: Top N venditori per numero di fatture emesse e importo medio.\n");
    printf("     (Parametro: numero risultati da visualizzare)\n");
    printf("\n\n");
}

//STAMPA RISULTATI

// Stampa una riga separatrice basata sulla larghezza delle colonne.
void print_separator(int* col_widths, int cols) {

    printf("+");
    for (int i = 0; i < cols; i++) {
        for (int j = 0; j < col_widths[i] + 2; j++) printf("-");
        printf("+");
    }
    printf("\n");
}

/*
 * Stampa i risultati di una query in una tabella ASCII allineata.
 * Calcola dinamicamente la larghezza di ogni colonna in base
 * al contenuto più lungo tra header e dati.
 */
void print_query_result(PGresult* result) {

    int rows = PQntuples(result);
    int cols = PQnfields(result);

    if (rows == 0) {
        printf("Nessun risultato trovato.\n");
        PQclear(result);
        return;
    }

    int* col_widths = malloc(cols * sizeof(int));
    if (!col_widths) {
        fprintf(stderr, "Errore di allocazione memoria.\n");
        PQclear(result);
        return;
    }

    for (int i = 0; i < cols; i++) {
        col_widths[i] = (int)strlen(PQfname(result, i));
        for (int j = 0; j < rows; j++) {
            int len = (int)strlen(PQgetvalue(result, j, i));
            if (len > col_widths[i]) col_widths[i] = len;
        }
    }

    print_separator(col_widths, cols);
    printf("|");
    for (int i = 0; i < cols; i++)
        printf(" %-*s |", col_widths[i], PQfname(result, i));
    printf("\n");
    print_separator(col_widths, cols);

    for (int i = 0; i < rows; i++) {
        printf("|");
        for (int j = 0; j < cols; j++)
            printf(" %-*s |", col_widths[j], PQgetvalue(result, i, j));
        printf("\n");
    }
    print_separator(col_widths, cols);

    printf("Totale righe: %d\n", rows);

    free(col_widths);
    PQclear(result);
}

/*
 * Attende che l'utente prema Invio prima di tornare al menu.
 * Evita che il menu sovrascriva immediatamente il risultato.
 */
void wait_for_enter() {
    printf("\nPremi Invio per tornare al menu...");
    fflush(stdout);
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

//SELEZIONE ED ESECUZIONE QUERY

PGresult* choose_query(PGconn* connection) {

    int n = 0;

    while (n < -1 || n == 0 || n > 5) {
        char* message = "\nDigitare:\n"
                        "  [-1] >> Esci\n"
                        "  [ 0] >> Mostra lista query\n"
                        "  [1-5] >> Seleziona query\n"
                        "Scelta: ";
        n = read_int_from_stdin(message);
        if (n == 0) {
            print_query_list();
        } else if (n < -1 || n > 5) {
            printf("Input non valido. Riprovare.\n");
            n = 0;
        }
    }

    if (n == -1) {
        printf("Uscita dal programma.\n");
        PQfinish(connection);
        exit(0);
    }

    // Query 1
    // Top N clienti ordinati per spesa totale.
    // Parametri: $1 = numero di risultati da visualizzare (default 10).
    if (n == 1) {
        const char* parameters[1];
        const char* query =
            "SELECT U.Nome, U.Cognome, "
            "       SUM(A.Totale) AS TotaleSpeso "
            "FROM Utente U "
            "JOIN Cliente C  ON U.Username = C.Utente "
            "JOIN Acquisto A ON C.Utente   = A.Cliente "
            "GROUP BY U.Username, U.Nome, U.Cognome "
            "ORDER BY TotaleSpeso DESC "
            "LIMIT $1;";

        int limite = read_int_from_stdin(
            "Inserisci il numero di risultati da visualizzare ([-1] >> default 10): ");
        if (limite <= 0) limite = 10;

        char limite_char[16];
        sprintf(limite_char, "%d", limite);
        parameters[0] = limite_char;

        return execute_parametric_query(connection, query, 1, parameters);
    }

    // Query 2
    // Fruitori con più di N prenotazioni.
    // Parametri: $1 = soglia minima prenotazioni (default 1).
    if (n == 2) {
        const char* parameters[1];
        const char* query =
            "SELECT U.Nome, U.Cognome, "
            "       COUNT(*) AS NumeroPrenotazioni "
            "FROM Utente U "
            "JOIN Fruitore F     ON U.Username = F.Utente "
            "JOIN Prenotazione P ON F.Utente   = P.Fruitore "
            "GROUP BY U.Username, U.Nome, U.Cognome "
            "HAVING COUNT(*) > $1 "
            "ORDER BY NumeroPrenotazioni DESC;";

        int soglia = read_int_from_stdin(
            "Inserisci la soglia minima di prenotazioni ([-1] >> default 1): ");
        if (soglia <= 0) soglia = 1;

        char soglia_char[16];
        sprintf(soglia_char, "%d", soglia);
        parameters[0] = soglia_char;

        return execute_parametric_query(connection, query, 1, parameters);
    }

    // Query 3
    // Top N corrieri per numero spedizioni e totale fatturato.
    // Parametri: $1 = numero di risultati da visualizzare (default 5).
    if (n == 3) {
        const char* parameters[1];
        const char* query =
            "SELECT C.Nome AS Corriere, "
            "       COUNT(S.ID_Spedizione) AS NumeroSpedizioni, "
            "       SUM(F.Importo_Totale)  AS TotaleFatturato "
            "FROM Corriere C "
            "JOIN Spedizione S ON C.Nome = S.Corriere "
            "JOIN Fattura F    ON S.Acquisto_Cliente = F.Acquisto_Cliente "
            "                 AND S.Acquisto_Data    = F.Acquisto_Data "
            "GROUP BY C.Nome "
            "ORDER BY NumeroSpedizioni DESC "
            "LIMIT $1;";

        int limite = read_int_from_stdin(
            "Inserisci il numero di risultati da visualizzare ([-1] >> default 5): ");
        if (limite <= 0) limite = 5;

        char limite_char[16];
        sprintf(limite_char, "%d", limite);
        parameters[0] = limite_char;

        return execute_parametric_query(connection, query, 1, parameters);
    }

    // Query 4
    // Top N contenuti digitali (Libri e DVD) più prenotati.
    // Parametri: $1 = numero di risultati da visualizzare (default 10).
    if (n == 4) {
        const char* parameters[1];
        const char* query =
            "SELECT * FROM ("
            "  SELECT O.Codice_A_Barre, "
            "         'Libro'        AS Tipo, "
            "         L.Autore       AS Autore_Regista, "
            "         L.Genere_Libro AS Genere, "
            "         COUNT(P.Oggetto) AS NumeroPrenotazioni "
            "  FROM Oggetto O "
            "  JOIN Libro L        ON O.Codice_A_Barre = L.Oggetto "
            "  JOIN Prenotazione P ON O.Codice_A_Barre = P.Oggetto "
            "  GROUP BY O.Codice_A_Barre, L.Autore, L.Genere_Libro "
            "  UNION ALL "
            "  SELECT O.Codice_A_Barre, "
            "         'DVD'         AS Tipo, "
            "         D.Regista     AS Autore_Regista, "
            "         D.Genere_DVD  AS Genere, "
            "         COUNT(P.Oggetto) AS NumeroPrenotazioni "
            "  FROM Oggetto O "
            "  JOIN DVD D          ON O.Codice_A_Barre = D.Oggetto "
            "  JOIN Prenotazione P ON O.Codice_A_Barre = P.Oggetto "
            "  GROUP BY O.Codice_A_Barre, D.Regista, D.Genere_DVD "
            ") AS Risultati "
            "ORDER BY NumeroPrenotazioni DESC "
            "LIMIT $1;";

        int limite = read_int_from_stdin(
            "Inserisci il numero di risultati da visualizzare ([-1] >> default 10): ");
        if (limite <= 0) limite = 10;

        char limite_char[16];
        sprintf(limite_char, "%d", limite);
        parameters[0] = limite_char;

        return execute_parametric_query(connection, query, 1, parameters);
    }

    // Query 5
    // Top N venditori per numero fatture emesse e importo medio.
    // Parametri: $1 = numero di risultati da visualizzare (default 2).
    if (n == 5) {
        const char* parameters[1];
        const char* query =
            "SELECT U.Nome, U.Cognome, "
            "       COUNT(F.Numero_Fattura)        AS NumeroFatture, "
            "       ROUND(AVG(F.Importo_Totale),2) AS MediaImporto "
            "FROM Utente U "
            "JOIN Venditore V ON U.Username = V.Utente "
            "JOIN Fattura F   ON V.Utente   = F.Venditore "
            "GROUP BY U.Username, U.Nome, U.Cognome "
            "ORDER BY MediaImporto DESC "
            "LIMIT $1;";

        int limite = read_int_from_stdin(
            "Inserisci il numero di risultati da visualizzare ([-1] >> default 2): ");
        if (limite <= 0) limite = 2;

        char limite_char[16];
        sprintf(limite_char, "%d", limite);
        parameters[0] = limite_char;

        return execute_parametric_query(connection, query, 1, parameters);
    }

    return NULL;
}

//ENTRY POINT

int main(int argc, char** argv) {

#ifdef DEBUG
    printf("Modalita DEBUG attiva "
           "[commentare #define DEBUG per la modalita RELEASE]\n");
    PGconn* connection = connect_to_DB(PG_USER, PG_PASS, PG_DB,
                                       PG_HOST, PG_PORT);
#else
    printf("Modalita RELEASE attiva\n");

    char user[50], pswd[50], db[50], ip[50], port[50];

    read_string_from_stdin(user, sizeof(user), "Inserire username DB: ");
    read_string_from_stdin(pswd, sizeof(pswd), "Inserire password DB: ");
    read_string_from_stdin(db,   sizeof(db),   "Inserire nome database: ");
    read_string_from_stdin(ip,   sizeof(ip),   "Inserire IP host: ");
    read_string_from_stdin(port, sizeof(port), "Inserire porta: ");

    PGconn* connection = connect_to_DB(user, pswd, db, ip, port);
#endif

    print_query_list();

    while (TRUE) {
        PGresult* result = choose_query(connection);

        if (result == NULL) {
            printf("Query non valida. Riprova.\n");
        } else {
            print_query_result(result);
            wait_for_enter();
        }
    }

    PQfinish(connection);
    return 0;
}