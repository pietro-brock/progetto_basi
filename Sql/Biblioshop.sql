CREATE TABLE Utente (
    Username        VARCHAR(50)  PRIMARY KEY,
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Password        VARCHAR(255) NOT NULL,
    Nome            VARCHAR(100) NOT NULL,
    Cognome         VARCHAR(100) NOT NULL,
    Via             VARCHAR(150) NOT NULL,
    CAP             VARCHAR(10)  NOT NULL,
    Civico          VARCHAR(10)  NOT NULL,
    Citta           VARCHAR(100) NOT NULL,
    Provincia       VARCHAR(50)  NOT NULL,
    Nazione         VARCHAR(100) NOT NULL
);

CREATE TABLE Fruitore (
    Utente          VARCHAR(50)  PRIMARY KEY,
    Numero_Tessera  VARCHAR(20)  NOT NULL UNIQUE,
    Data_Iscrizione DATE         NOT NULL,
    Tipo_Tessera    VARCHAR(50)  NOT NULL,
    FOREIGN KEY (Utente) REFERENCES Utente(Username)
);

CREATE TABLE Cliente (
    Utente          VARCHAR(50)  PRIMARY KEY,
    Punti_Bonus     INT          NOT NULL DEFAULT 0,
    FOREIGN KEY (Utente) REFERENCES Utente(Username)
);

CREATE TABLE Venditore (
    Utente          VARCHAR(50)  PRIMARY KEY,
    P_IVA           VARCHAR(16)  NOT NULL UNIQUE,
    FOREIGN KEY (Utente) REFERENCES Utente(Username)
);

CREATE TABLE Oggetto (
    Codice_A_Barre  VARCHAR(20)  PRIMARY KEY,
    Prezzo          NUMERIC(10,2) NOT NULL,
    Giacenza        INT           NOT NULL
);

CREATE TABLE DVD (
    Oggetto         VARCHAR(20)  PRIMARY KEY,
    Genere_DVD      VARCHAR(50)  NOT NULL,
    Regista         VARCHAR(100) NOT NULL,
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Libro (
    Oggetto         VARCHAR(20)  PRIMARY KEY,
    Autore          VARCHAR(100) NOT NULL,
    Genere_Libro    VARCHAR(50)  NOT NULL,
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Maglia (
    Oggetto         VARCHAR(20)  PRIMARY KEY,
    Tessuto         VARCHAR(50)  NOT NULL,
    Taglia          VARCHAR(5)   NOT NULL,
    Colore          VARCHAR(50)  NOT NULL,
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Tazza (
    Oggetto         VARCHAR(20)  PRIMARY KEY,
    Colore          VARCHAR(50)  NOT NULL,
    Dimensione      VARCHAR(20)  NOT NULL,
    Materiale       VARCHAR(50)  NOT NULL,
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Acquisto (
    Cliente         VARCHAR(50)  NOT NULL,
    Data_Acquisto   TIMESTAMP    NOT NULL,
    Totale          NUMERIC(10,2)NOT NULL,
    Punti_Guadagnati INT         NOT NULL DEFAULT 0,
    Punti_Utilizzati INT         NOT NULL DEFAULT 0,
    PRIMARY KEY (Cliente, Data_Acquisto),
    FOREIGN KEY (Cliente) REFERENCES Cliente(Utente)
);

CREATE TABLE Fattura (
    Numero_Fattura  SERIAL       PRIMARY KEY,
    Importo_Totale  NUMERIC(10,2)NOT NULL,
    Data_Emissione  DATE         NOT NULL,
    Venditore       VARCHAR(50)  NOT NULL,
    Acquisto_Cliente VARCHAR(50) NOT NULL,
    Acquisto_Data   TIMESTAMP    NOT NULL,
    UNIQUE (Acquisto_Cliente, Acquisto_Data),
    FOREIGN KEY (Venditore) REFERENCES Venditore(Utente),
    FOREIGN KEY (Acquisto_Cliente, Acquisto_Data) REFERENCES Acquisto(Cliente, Data_Acquisto)
);

CREATE TABLE Contenuto (
    Acquisto_Cliente VARCHAR(50) NOT NULL,
    Acquisto_Data    TIMESTAMP   NOT NULL,
    Oggetto          VARCHAR(20) NOT NULL,
    Quantita         INT         NOT NULL DEFAULT 1,
    PRIMARY KEY (Acquisto_Cliente, Acquisto_Data, Oggetto),
    FOREIGN KEY (Acquisto_Cliente, Acquisto_Data) REFERENCES Acquisto(Cliente, Data_Acquisto),
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Corriere (
    Nome                VARCHAR(100) PRIMARY KEY,
    Email_Corriere      VARCHAR(100) NOT NULL UNIQUE,
    Telefono_Assistenza VARCHAR(20)  NOT NULL,
    Package_Tracking_URL VARCHAR(255)NOT NULL
);

CREATE TABLE Spedizione (
    ID_Spedizione    SERIAL       PRIMARY KEY,
    Stato_Spedizione VARCHAR(50)  NOT NULL,
    Dettagli         TEXT,
    Via              VARCHAR(150) NOT NULL,
    CAP              VARCHAR(10)  NOT NULL,
    Civico           VARCHAR(10)  NOT NULL,
    Citta            VARCHAR(100) NOT NULL,
    Provincia        VARCHAR(50)  NOT NULL,
    Nazione          VARCHAR(100) NOT NULL,
    Acquisto_Cliente VARCHAR(50)  NOT NULL,
    Acquisto_Data    TIMESTAMP    NOT NULL,
    Corriere         VARCHAR(100) NOT NULL,
    UNIQUE (Acquisto_Cliente, Acquisto_Data),
    FOREIGN KEY (Acquisto_Cliente, Acquisto_Data) REFERENCES Acquisto(Cliente, Data_Acquisto),
    FOREIGN KEY (Corriere) REFERENCES Corriere(Nome)
);

CREATE TABLE Prenotazione (
    Fruitore        VARCHAR(50)  NOT NULL,
    Data            DATE         NOT NULL,
    Stato           VARCHAR(50)  NOT NULL,
    Oggetto         VARCHAR(20)  NOT NULL,
    PRIMARY KEY (Fruitore, Data, Oggetto),
    FOREIGN KEY (Fruitore) REFERENCES Fruitore(Utente),
    FOREIGN KEY (Oggetto) REFERENCES Oggetto(Codice_A_Barre)
);

CREATE TABLE Prestito (
    Prenotazione_Fruitore VARCHAR(50) NOT NULL,
    Prenotazione_Data     DATE        NOT NULL,
    Prenotazione_Oggetto  VARCHAR(20) NOT NULL,
    Data_Inizio           DATE        NOT NULL,
    Data_Fine             DATE        NOT NULL,
    PRIMARY KEY (Prenotazione_Fruitore, Prenotazione_Data, Prenotazione_Oggetto),
    FOREIGN KEY (Prenotazione_Fruitore, Prenotazione_Data, Prenotazione_Oggetto)
        REFERENCES Prenotazione(Fruitore, Data, Oggetto)
);

-- TRIGGER: un utente può appartenere a una sola categoria

CREATE OR REPLACE FUNCTION check_categoria_unica()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'fruitore' THEN
        IF EXISTS (SELECT 1 FROM Cliente   WHERE Utente = NEW.Utente)
        OR EXISTS (SELECT 1 FROM Venditore WHERE Utente = NEW.Utente) THEN
            RAISE EXCEPTION
            'Utente % appartiene già a un''altra categoria.', NEW.Utente;
        END IF;
    ELSIF TG_TABLE_NAME = 'cliente' THEN
        IF EXISTS (SELECT 1 FROM Fruitore  WHERE Utente = NEW.Utente)
        OR EXISTS (SELECT 1 FROM Venditore WHERE Utente = NEW.Utente) THEN
            RAISE EXCEPTION
            'Utente % appartiene già a un''altra categoria.', NEW.Utente;
        END IF;
    ELSIF TG_TABLE_NAME = 'venditore' THEN
        IF EXISTS (SELECT 1 FROM Fruitore WHERE Utente = NEW.Utente)
        OR EXISTS (SELECT 1 FROM Cliente  WHERE Utente = NEW.Utente) THEN
            RAISE EXCEPTION
            'Utente % appartiene già a un''altra categoria.', NEW.Utente;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_categoria_unica_fruitore
BEFORE INSERT ON Fruitore
FOR EACH ROW EXECUTE FUNCTION check_categoria_unica();

CREATE TRIGGER trg_categoria_unica_cliente
BEFORE INSERT ON Cliente
FOR EACH ROW EXECUTE FUNCTION check_categoria_unica();

CREATE TRIGGER trg_categoria_unica_venditore
BEFORE INSERT ON Venditore
FOR EACH ROW EXECUTE FUNCTION check_categoria_unica();

-- TRIGGER: le prenotazioni riguardano solo Libri o DVD

CREATE OR REPLACE FUNCTION check_prenotazione_digitale()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Libro WHERE Oggetto = NEW.Oggetto)
    AND NOT EXISTS (SELECT 1 FROM DVD  WHERE Oggetto = NEW.Oggetto) THEN
        RAISE EXCEPTION
        'Prenotazione non valida: l''oggetto % non è un contenuto digitale.',
        NEW.Oggetto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_prenotazione_digitale
BEFORE INSERT OR UPDATE OF Oggetto
ON Prenotazione
FOR EACH ROW
EXECUTE FUNCTION check_prenotazione_digitale();

--  INSERT

-- Account degli utenti che sono Clienti (nessun suffisso)
INSERT INTO Utente (Username, Email, Password, Nome, Cognome, Via, CAP, Civico, Citta, Provincia, Nazione) VALUES
('mrossi',      'mario.rossi@email.it',        'hashed_pw_01', 'Mario',     'Rossi',      'Via Roma',            '00100', '12',  'Roma',      'RM', 'Italia'),
('gverdi',      'giulia.verdi@email.it',       'hashed_pw_02', 'Giulia',    'Verdi',      'Via Milano',          '20100', '5',   'Milano',    'MI', 'Italia'),
('lbianchi',    'luca.bianchi@email.it',       'hashed_pw_03', 'Luca',      'Bianchi',    'Via Napoli',          '80100', '33',  'Napoli',    'NA', 'Italia'),
('sfontana',    'sara.fontana@email.it',       'hashed_pw_04', 'Sara',      'Fontana',    'Corso Torino',        '10100', '7',   'Torino',    'TO', 'Italia'),
('aferrari',    'antonio.ferrari@email.it',    'hashed_pw_05', 'Antonio',   'Ferrari',    'Via Bologna',         '40100', '21',  'Bologna',   'BO', 'Italia'),
('clobello',    'chiara.lobello@email.it',     'hashed_pw_06', 'Chiara',    'Lobello',    'Via Palermo',         '90100', '8',   'Palermo',   'PA', 'Italia'),
('fmancini',    'fabio.mancini@email.it',      'hashed_pw_07', 'Fabio',     'Mancini',    'Via Firenze',         '50100', '14',  'Firenze',   'FI', 'Italia'),
('erusso',      'elena.russo@email.it',        'hashed_pw_08', 'Elena',     'Russo',      'Via Venezia',         '30100', '2',   'Venezia',   'VE', 'Italia'),
('pconti',      'paolo.conti@email.it',        'hashed_pw_09', 'Paolo',     'Conti',      'Viale Genova',        '16100', '18',  'Genova',    'GE', 'Italia'),
('vdeluca',     'valentina.deluca@email.it',   'hashed_pw_10', 'Valentina', 'De Luca',    'Piazza Bari',         '70100', '3',   'Bari',      'BA', 'Italia'),
('nmarino',     'nicola.marino@email.it',      'hashed_pw_11', 'Nicola',    'Marino',     'Via Catania',         '95100', '9',   'Catania',   'CT', 'Italia'),
('agallo',      'anna.gallo@email.it',         'hashed_pw_12', 'Anna',      'Gallo',      'Via Verona',          '37100', '11',  'Verona',    'VR', 'Italia'),
('rguerra',     'roberto.guerra@email.it',     'hashed_pw_13', 'Roberto',   'Guerra',     'Corso Messina',       '98100', '6',   'Messina',   'ME', 'Italia'),
('mtagliaferri','marco.taglie@email.it',       'hashed_pw_14', 'Marco',     'Tagliaferri','Via Padova',          '35100', '29',  'Padova',    'PD', 'Italia'),
('lsalvatore',  'laura.salvatore@email.it',    'hashed_pw_15', 'Laura',     'Salvatore',  'Via Trieste',         '34100', '17',  'Trieste',   'TS', 'Italia'),
('gcosta',      'giovanni.costa@email.it',     'hashed_pw_16', 'Giovanni',  'Costa',      'Via Brescia',         '25100', '40',  'Brescia',   'BS', 'Italia'),
('mfumagalli',  'monica.fumagalli@email.it',   'hashed_pw_17', 'Monica',    'Fumagalli',  'Via Bergamo',         '24100', '55',  'Bergamo',   'BG', 'Italia'),
('ttrentini',   'tomas.trentini@email.it',     'hashed_pw_18', 'Tomas',     'Trentini',   'Via Trento',          '38100', '10',  'Trento',    'TN', 'Italia'),
('dmarino',     'davide.marino@email.it',      'hashed_pw_21', 'Davide',    'Marino',     'Via Lecce',           '73100', '4',   'Lecce',     'LE', 'Italia'),
('fpalumbo',    'francesca.palumbo@email.it',  'hashed_pw_22', 'Francesca', 'Palumbo',    'Via Taranto',         '74100', '19',  'Taranto',   'TA', 'Italia'),
('gsantoro',    'giuseppe.santoro@email.it',   'hashed_pw_23', 'Giuseppe',  'Santoro',    'Corso Foggia',        '71100', '8',   'Foggia',    'FG', 'Italia'),
('mciccone',    'martina.ciccone@email.it',    'hashed_pw_24', 'Martina',   'Ciccone',    'Via Reggio',          '89100', '3',   'Reggio Calabria','RC','Italia'),
('abrunetti',   'andrea.brunetti@email.it',    'hashed_pw_25', 'Andrea',    'Brunetti',   'Via Perugia',         '06100', '22',  'Perugia',   'PG', 'Italia'),
('igiordano',   'irene.giordano@email.it',     'hashed_pw_26', 'Irene',     'Giordano',   'Via Ancona',          '60100', '11',  'Ancona',    'AN', 'Italia'),
('cbarone',     'carlo.barone@email.it',       'hashed_pw_27', 'Carlo',     'Barone',     'Piazza Pescara',      '65100', '6',   'Pescara',   'PE', 'Italia'),
('ldonati',     'lucia.donati@email.it',       'hashed_pw_28', 'Lucia',     'Donati',     'Via Livorno',         '57100', '30',  'Livorno',   'LI', 'Italia'),
('mquattrini',  'matteo.quattrini@email.it',   'hashed_pw_29', 'Matteo',    'Quattrini',  'Via Prato',           '59100', '15',  'Prato',     'PO', 'Italia'),
('vsergi',      'valentino.sergi@email.it',    'hashed_pw_30', 'Valentino', 'Sergi',      'Via Cosenza',         '87100', '9',   'Cosenza',   'CS', 'Italia'),
('tneri',       'teresa.neri@email.it',        'hashed_pw_31', 'Teresa',    'Neri',       'Via Modena',          '41100', '44',  'Modena',    'MO', 'Italia'),
('rcaputo',     'riccardo.caputo@email.it',    'hashed_pw_32', 'Riccardo',  'Caputo',     'Via Parma',           '43100', '7',   'Parma',     'PR', 'Italia'),
('odesantis',   'ornella.desantis@email.it',   'hashed_pw_33', 'Ornella',   'De Santis',  'Via Ravenna',         '48100', '13',  'Ravenna',   'RA', 'Italia'),
('bgreco',      'beatrice.greco@email.it',     'hashed_pw_34', 'Beatrice',  'Greco',      'Via Ferrara',         '44100', '25',  'Ferrara',   'FE', 'Italia'),
('sfabbri',     'simone.fabbri@email.it',      'hashed_pw_35', 'Simone',    'Fabbri',     'Via Rimini',          '47900', '16',  'Rimini',    'RN', 'Italia'),
('ecaruso',     'elisa.caruso@email.it',       'hashed_pw_36', 'Elisa',     'Caruso',     'Via Salerno',         '84100', '5',   'Salerno',   'SA', 'Italia'),
('tviola',      'tommaso.viola@email.it',      'hashed_pw_37', 'Tommaso',   'Viola',      'Via Sassari',         '07100', '20',  'Sassari',   'SS', 'Italia'),
('nardito',     'noemi.ardito@email.it',       'hashed_pw_38', 'Noemi',     'Ardito',     'Via Cagliari',        '09100', '34',  'Cagliari',  'CA', 'Italia'),
('pfiorentino', 'pietro.fiorentino@email.it',  'hashed_pw_39', 'Pietro',    'Fiorentino', 'Corso Udine',         '33100', '12',  'Udine',     'UD', 'Italia'),
('cgentile',    'cristina.gentile@email.it',   'hashed_pw_40', 'Cristina',  'Gentile',    'Via Aosta',           '11100', '2',   'Aosta',     'AO', 'Italia');
-- Account degli utenti che sono Venditori (nessun suffisso)
INSERT INTO Utente (Username, Email, Password, Nome, Cognome, Via, CAP, Civico, Citta, Provincia, Nazione) VALUES
('vlogistica',  'vendite@logistica.it',        'hashed_pw_19', 'Logistica', 'Shop',       'Via Industriale',     '20090', '1',   'Segrate',   'MI', 'Italia'),
('edigitale',   'info@edigitale.it',           'hashed_pw_20', 'Tutto',     'Digitale',   'Via Commercio',       '00144', '77',  'Roma',      'RM', 'Italia');
-- Account degli utenti fruitori (suffisso _f).
-- Account separati, che rispettano il vincolo di categoria unica.
INSERT INTO Utente (Username, Email, Password, Nome, Cognome, Via, CAP, Civico, Citta, Provincia, Nazione) VALUES
('mrossi_f',     'mario.rossi.fru@email.it',       'hashed_pw_f01', 'Mario',     'Rossi',      'Via Roma',            '00100', '12',  'Roma',      'RM', 'Italia'),
('gverdi_f',     'giulia.verdi.fru@email.it',      'hashed_pw_f02', 'Giulia',    'Verdi',      'Via Milano',          '20100', '5',   'Milano',    'MI', 'Italia'),
('lbianchi_f',   'luca.bianchi.fru@email.it',      'hashed_pw_f03', 'Luca',      'Bianchi',    'Via Napoli',          '80100', '33',  'Napoli',    'NA', 'Italia'),
('sfontana_f',   'sara.fontana.fru@email.it',      'hashed_pw_f04', 'Sara',      'Fontana',    'Corso Torino',        '10100', '7',   'Torino',    'TO', 'Italia'),
('aferrari_f',   'antonio.ferrari.fru@email.it',   'hashed_pw_f05', 'Antonio',   'Ferrari',    'Via Bologna',         '40100', '21',  'Bologna',   'BO', 'Italia'),
('clobello_f',   'chiara.lobello.fru@email.it',    'hashed_pw_f06', 'Chiara',    'Lobello',    'Via Palermo',         '90100', '8',   'Palermo',   'PA', 'Italia'),
('fmancini_f',   'fabio.mancini.fru@email.it',     'hashed_pw_f07', 'Fabio',     'Mancini',    'Via Firenze',         '50100', '14',  'Firenze',   'FI', 'Italia'),
('erusso_f',     'elena.russo.fru@email.it',       'hashed_pw_f08', 'Elena',     'Russo',      'Via Venezia',         '30100', '2',   'Venezia',   'VE', 'Italia'),
('pconti_f',     'paolo.conti.fru@email.it',       'hashed_pw_f09', 'Paolo',     'Conti',      'Viale Genova',        '16100', '18',  'Genova',    'GE', 'Italia'),
('vdeluca_f',    'valentina.deluca.fru@email.it',  'hashed_pw_f10', 'Valentina', 'De Luca',    'Piazza Bari',         '70100', '3',   'Bari',      'BA', 'Italia'),
('dmarino_f',    'davide.marino.fru@email.it',     'hashed_pw_f11', 'Davide',    'Marino',     'Via Lecce',           '73100', '4',   'Lecce',     'LE', 'Italia'),
('fpalumbo_f',   'francesca.palumbo.fru@email.it', 'hashed_pw_f12', 'Francesca', 'Palumbo',    'Via Taranto',         '74100', '19',  'Taranto',   'TA', 'Italia'),
('gsantoro_f',   'giuseppe.santoro.fru@email.it',  'hashed_pw_f13', 'Giuseppe',  'Santoro',    'Corso Foggia',        '71100', '8',   'Foggia',    'FG', 'Italia'),
('mciccone_f',   'martina.ciccone.fru@email.it',   'hashed_pw_f14', 'Martina',   'Ciccone',    'Via Reggio',          '89100', '3',   'Reggio Calabria','RC','Italia'),
('abrunetti_f',  'andrea.brunetti.fru@email.it',   'hashed_pw_f15', 'Andrea',    'Brunetti',   'Via Perugia',         '06100', '22',  'Perugia',   'PG', 'Italia'),
('igiordano_f',  'irene.giordano.fru@email.it',    'hashed_pw_f16', 'Irene',     'Giordano',   'Via Ancona',          '60100', '11',  'Ancona',    'AN', 'Italia'),
('cbarone_f',    'carlo.barone.fru@email.it',      'hashed_pw_f17', 'Carlo',     'Barone',     'Piazza Pescara',      '65100', '6',   'Pescara',   'PE', 'Italia'),
('ldonati_f',    'lucia.donati.fru@email.it',      'hashed_pw_f18', 'Lucia',     'Donati',     'Via Livorno',         '57100', '30',  'Livorno',   'LI', 'Italia'),
('mquattrini_f', 'matteo.quattrini.fru@email.it',  'hashed_pw_f19', 'Matteo',    'Quattrini',  'Via Prato',           '59100', '15',  'Prato',     'PO', 'Italia'),
('vsergi_f',     'valentino.sergi.fru@email.it',   'hashed_pw_f20', 'Valentino', 'Sergi',      'Via Cosenza',         '87100', '9',   'Cosenza',   'CS', 'Italia');

INSERT INTO Fruitore (Utente, Numero_Tessera, Data_Iscrizione, Tipo_Tessera) VALUES
('mrossi_f',     'TES-0001', '2023-01-15', 'Standard'),
('gverdi_f',     'TES-0002', '2023-02-20', 'Studente'),
('lbianchi_f',   'TES-0003', '2023-03-10', 'Anziano'),
('sfontana_f',   'TES-0004', '2023-04-05', 'Standard'),
('aferrari_f',   'TES-0005', '2023-05-18', 'Studente'),
('clobello_f',   'TES-0006', '2023-06-22', 'Standard'),
('fmancini_f',   'TES-0007', '2023-07-30', 'Studente'),
('erusso_f',     'TES-0008', '2023-08-14', 'Anziano'),
('pconti_f',     'TES-0009', '2023-09-01', 'Standard'),
('vdeluca_f',    'TES-0010', '2023-10-11', 'Studente'),
('dmarino_f',    'TES-0011', '2023-11-03', 'Standard'),
('fpalumbo_f',   'TES-0012', '2023-11-18', 'Studente'),
('gsantoro_f',   'TES-0013', '2023-12-01', 'Anziano'),
('mciccone_f',   'TES-0014', '2024-01-07', 'Studente'),
('abrunetti_f',  'TES-0015', '2024-01-22', 'Standard'),
('igiordano_f',  'TES-0016', '2024-02-10', 'Studente'),
('cbarone_f',    'TES-0017', '2024-02-28', 'Standard'),
('ldonati_f',    'TES-0018', '2024-03-15', 'Anziano'),
('mquattrini_f', 'TES-0019', '2024-04-02', 'Studente'),
('vsergi_f',     'TES-0020', '2024-04-19', 'Standard');

INSERT INTO Cliente (Utente, Punti_Bonus) VALUES
('mrossi',      120),
('gverdi',      45),
('lbianchi',    300),
('sfontana',    0),
('aferrari',    75),
('clobello',    210),
('fmancini',    60),
('erusso',      180),
('pconti',      90),
('vdeluca',     15),
('nmarino',     50),
('agallo',      130),
('rguerra',     0),
('mtagliaferri',240),
('lsalvatore',  85),
('dmarino',     35),
('fpalumbo',    110),
('gsantoro',    0),
('mciccone',    275),
('abrunetti',   60),
('igiordano',   190),
('cbarone',     45),
('ldonati',     320),
('mquattrini',  0),
('vsergi',      155),
('tneri',       80),
('rcaputo',     25),
('odesantis',   410),
('bgreco',      70),
('sfabbri',     140),
('ecaruso',     0),
('tviola',      0),
('nardito',     0),
('pfiorentino', 0),
('cgentile',    0);

INSERT INTO Venditore (Utente, P_IVA) VALUES
('vlogistica', 'IT01234567890'),
('edigitale',  'IT09876543210');

INSERT INTO Corriere (Nome, Email_Corriere, Telefono_Assistenza, Package_Tracking_URL) VALUES
('BRT',      'assistenza@brt.it',      '0287654321', 'https://www.brt.it/tracking'),
('GLS',      'support@gls-italy.com',  '0298765432', 'https://gls-group.eu/tracking'),
('DHL',      'info@dhl.it',            '0299887766', 'https://www.dhl.com/it/tracking'),
('Poste',    'corriere@poste.it',      '803160',     'https://www.poste.it/tracking'),
('Nexive',   'info@nexive.it',         '0265432109', 'https://www.nexive.it/tracking');

-- Oggetti: libri
INSERT INTO Oggetto (Codice_A_Barre, Prezzo, Giacenza) VALUES
('LIB-0001', 14.90,  20),
('LIB-0002', 12.50,  15),
('LIB-0003', 18.00,  10),
('LIB-0004', 9.90,   30),
('LIB-0005', 22.00,  8),
('LIB-0006', 11.50,  25),
('LIB-0007', 16.90,  12),
('LIB-0008', 13.00,  18),
('LIB-0009', 19.90,  7),
('LIB-0010', 10.50,  22),
('LIB-0011', 15.00,  14),
('LIB-0012', 17.50,  9),
('LIB-0013', 13.50,  16),
('LIB-0014', 21.00,  11),
('LIB-0015', 8.90,   28),
('LIB-0016', 17.00,  13),
('LIB-0017', 14.00,  19),
('LIB-0018', 20.50,  6),
('LIB-0019', 11.00,  23),
('LIB-0020', 16.00,  10),
('LIB-0021', 18.50,  8),
('LIB-0022', 12.00,  20),
('LIB-0023', 15.50,  17),
('LIB-0024', 9.50,   32),
-- DVD
('DVD-0001', 9.99,   40),
('DVD-0002', 12.99,  35),
('DVD-0003', 8.99,   50),
('DVD-0004', 14.99,  20),
('DVD-0005', 11.99,  30),
('DVD-0006', 13.99,  25),
('DVD-0007', 7.99,   45),
('DVD-0008', 16.99,  15),
('DVD-0009',  10.99,  38),
('DVD-0010',  13.99,  28),
('DVD-0011',  9.99,   42),
('DVD-0012',  15.99,  18),
('DVD-0013',  11.99,  33),
('DVD-0014',  8.99,   48),
('DVD-0015',  14.99,  22),
('DVD-0016',  12.99,  27),
-- Maglie
('MAG-0001', 24.90,  50),
('MAG-0002', 24.90,  50),
('MAG-0003', 29.90,  30),
('MAG-0004', 19.90,  60),
('MAG-0005', 27.90,  45),
('MAG-0006', 22.90,  55),
('MAG-0007', 31.90,  25),
('MAG-0008', 19.90,  65),
-- Tazze
('TAZ-0001', 12.90,  80),
('TAZ-0002', 14.90,  70),
('TAZ-0003', 9.90,   100),
('TAZ-0004', 16.90,  60),
('TAZ-0005', 11.90,  90),
('TAZ-0006', 13.90,  75),
('TAZ-0007', 15.90,  55),
('TAZ-0008', 10.90,  110);

INSERT INTO Libro (Oggetto, Autore, Genere_Libro) VALUES
('LIB-0001', 'Italo Calvino',        'Narrativa'),
('LIB-0002', 'Umberto Eco',          'Romanzo storico'),
('LIB-0003', 'Elena Ferrante',       'Narrativa'),
('LIB-0004', 'Andrea Camilleri',     'Giallo'),
('LIB-0005', 'Primo Levi',           'Autobiografia'),
('LIB-0006', 'Luigi Pirandello',     'Teatro'),
('LIB-0007', 'Giovanni Verga',       'Verismo'),
('LIB-0008', 'Natalia Ginzburg',     'Narrativa'),
('LIB-0009', 'Dino Buzzati',         'Fantasy'),
('LIB-0010', 'Carlo Goldoni',        'Teatro'),
('LIB-0011', 'Alberto Moravia',      'Narrativa'),
('LIB-0012', 'Grazia Deledda',       'Narrativa'),
('LIB-0013', 'Cesare Pavese',         'Narrativa'),
('LIB-0014', 'Giorgio Bassani',       'Romanzo storico'),
('LIB-0015', 'Elsa Morante',          'Narrativa'),
('LIB-0016', 'Leonardo Sciascia',     'Giallo'),
('LIB-0017', 'Vasco Pratolini',       'Narrativa'),
('LIB-0018', 'Carlo Levi',            'Autobiografia'),
('LIB-0019', 'Pier Paolo Pasolini',   'Poesia'),
('LIB-0020', 'Beppe Fenoglio',        'Narrativa'),
('LIB-0021', 'Salvatore Quasimodo',   'Poesia'),
('LIB-0022', 'Corrado Alvaro',        'Narrativa'),
('LIB-0023', 'Francesco De Sanctis',  'Saggio'),
('LIB-0024', 'Ippolito Nievo',        'Romanzo storico');

INSERT INTO DVD (Oggetto, Genere_DVD, Regista) VALUES
('DVD-0001', 'Commedia',    'Roberto Benigni'),
('DVD-0002', 'Drammatico',  'Federico Fellini'),
('DVD-0003', 'Thriller',    'Dario Argento'),
('DVD-0004', 'Biografico',  'Nanni Moretti'),
('DVD-0005', 'Commedia',    'Paolo Sorrentino'),
('DVD-0006', 'Drammatico',  'Luchino Visconti'),
('DVD-0007', 'Animazione',  'Enzo d Alo'),
('DVD-0008', 'Storico',     'Bernardo Bertolucci'),
('DVD-0009',  'Commedia',    'Mario Monicelli'),
('DVD-0010',  'Drammatico',  'Michelangelo Antonioni'),
('DVD-0011',  'Thriller',    'Mario Bava'),
('DVD-0012',  'Storico',     'Pier Paolo Pasolini'),
('DVD-0013',  'Commedia',    'Ettore Scola'),
('DVD-0014',  'Animazione',  'Bruno Bozzetto'),
('DVD-0015',  'Drammatico',  'Vittorio De Sica'),
('DVD-0016',  'Avventura',   'Sergio Leone');

INSERT INTO Maglia (Oggetto, Tessuto, Taglia, Colore) VALUES
('MAG-0001', 'Cotone', 'M',  'Blu'),
('MAG-0002', 'Cotone', 'L',  'Bianco'),
('MAG-0003', 'Poliestere', 'S', 'Nero'),
('MAG-0004', 'Cotone', 'XL', 'Rosso'),
('MAG-0005', 'Cotone',     'XS', 'Verde'),
('MAG-0006', 'Lino',       'M',  'Grigio'),
('MAG-0007', 'Poliestere', 'L',  'Giallo'),
('MAG-0008', 'Cotone',     'XL', 'Viola');

INSERT INTO Tazza (Oggetto, Colore, Dimensione, Materiale) VALUES
('TAZ-0001', 'Bianco',  '300ml', 'Ceramica'),
('TAZ-0002', 'Nero',    '400ml', 'Porcellana'),
('TAZ-0003', 'Blu',     '250ml', 'Ceramica'),
('TAZ-0004', 'Rosso',   '500ml', 'Vetro'),
('TAZ-0005', 'Verde',    '350ml', 'Ceramica'),
('TAZ-0006', 'Giallo',   '300ml', 'Porcellana'),
('TAZ-0007', 'Grigio',   '450ml', 'Ceramica'),
('TAZ-0008', 'Arancione','250ml', 'Vetro');

INSERT INTO Acquisto (Cliente, Data_Acquisto, Totale, Punti_Guadagnati, Punti_Utilizzati) VALUES
('mrossi',       '2024-01-10 09:14:22', 27.40,  27,  0),
('gverdi',       '2024-01-15 11:03:47', 14.90,  14,  0),
('lbianchi',     '2024-02-01 16:45:09', 34.88,  29,  5),
('sfontana',     '2024-02-14 10:22:31', 24.90,  24,  0),
('aferrari',     '2024-02-20 14:58:03', 22.98,  22,  0),
('clobello',     '2024-03-05 08:37:55', 39.80,  29, 10),
('fmancini',     '2024-03-12 19:11:40', 12.90,  12,  0),
('erusso',       '2024-03-20 13:26:18', 46.88,  36, 10),
('pconti',       '2024-04-02 17:44:05', 9.90,    9,  0),
('vdeluca',      '2024-04-18 09:58:29', 14.99,  14,  0),
('nmarino',      '2024-05-03 12:07:53', 29.90,  29,  0),
('agallo',       '2024-05-22 15:33:41', 27.89,  27,  0),
('rguerra',      '2024-06-01 10:49:17', 12.50,  12,  0),
('mtagliaferri', '2024-06-15 21:05:02', 57.78,  47, 10),
('lsalvatore',   '2024-07-04 08:21:36', 16.90,  16,  0),
('mrossi',       '2024-07-19 14:37:59', 22.00,  22,  0),
('gverdi',       '2024-08-08 11:52:44', 21.98,  21,  0),
('lbianchi',     '2024-08-25 16:18:27', 19.90,  14,  5),
('clobello',     '2024-09-10 09:03:51', 24.90,  24,  0),
('erusso',       '2024-09-28 20:41:13', 31.90,  26,  5),
('dmarino',      '2024-01-22 13:29:08', 13.50,  13,  0),
('fpalumbo',     '2024-01-28 17:46:35', 23.98,  23,  0),
('gsantoro',     '2024-02-05 10:13:22', 10.99,  10,  0),
('mciccone',     '2024-02-18 15:57:44', 44.90,  34, 10),
('abrunetti',    '2024-03-03 09:42:19', 21.00,  21,  0),
('igiordano',    '2024-03-22 18:08:33', 38.80,  28, 10),
('cbarone',      '2024-04-08 11:24:07', 11.90,  11,  0),
('ldonati',      '2024-04-25 14:39:51', 51.80,  41, 10),
('mquattrini',   '2024-05-07 08:55:26', 9.99,    9,  0),
('vsergi',       '2024-05-19 16:12:48', 27.90,  27,  0),
('tneri',        '2024-06-03 12:47:03', 15.90,  15,  0),
('rcaputo',      '2024-06-20 09:31:59', 20.50,  20,  0),
('odesantis',    '2024-07-08 22:14:37', 62.70,  52, 10),
('bgreco',       '2024-07-25 10:06:22', 24.90,  24,  0),
('sfabbri',      '2024-08-11 15:43:09', 17.00,  17,  0),
('ecaruso',      '2024-08-28 13:27:54', 31.88,  31,  0),
('tviola',       '2024-09-14 08:19:41', 13.99,  13,  0),
('nardito',      '2024-09-30 17:52:16', 26.90,  26,  0),
('pfiorentino',  '2024-10-16 11:38:45', 19.90,  19,  0),
('cgentile',     '2024-11-02 14:04:28', 33.89,  28,  5),
('dmarino',      '2024-11-18 09:57:33', 21.98,  21,  0),
('fpalumbo',     '2024-12-05 16:22:11', 14.90,  14,  0),
('mciccone',     '2024-12-20 12:48:57', 29.90,  24,  5),
('ldonati',      '2025-01-08 10:31:44', 18.50,  18,  0),
('odesantis',    '2025-01-24 19:15:02', 43.80,  38,  5),
('vsergi',       '2025-02-10 08:43:37', 12.99,  12,  0),
('igiordano',    '2025-02-25 13:59:21', 35.80,  30,  5),
('bgreco',       '2025-03-12 11:26:48', 22.90,  22,  0),
('sfabbri',      '2025-03-28 16:07:15', 15.99,  15,  0),
('tneri',        '2025-04-14 09:53:29', 28.90,  28,  0);

INSERT INTO Fattura (Importo_Totale, Data_Emissione, Venditore, Acquisto_Cliente, Acquisto_Data) VALUES
(27.40,  '2024-01-10', 'vlogistica', 'mrossi',        '2024-01-10 09:14:22'),
(14.90,  '2024-01-15', 'edigitale',  'gverdi',        '2024-01-15 11:03:47'),
(34.88,  '2024-02-02', 'vlogistica', 'lbianchi',      '2024-02-01 16:45:09'),
(24.90,  '2024-02-14', 'vlogistica', 'sfontana',      '2024-02-14 10:22:31'),
(22.98,  '2024-02-20', 'edigitale',  'aferrari',      '2024-02-20 14:58:03'),
(39.80,  '2024-03-06', 'vlogistica', 'clobello',      '2024-03-05 08:37:55'),
(12.90,  '2024-03-12', 'edigitale',  'fmancini',      '2024-03-12 19:11:40'),
(46.88,  '2024-03-21', 'vlogistica', 'erusso',        '2024-03-20 13:26:18'),
(9.90,   '2024-04-02', 'edigitale',  'pconti',        '2024-04-02 17:44:05'),
(14.99,  '2024-04-18', 'vlogistica', 'vdeluca',       '2024-04-18 09:58:29'),
(29.90,  '2024-05-03', 'vlogistica', 'nmarino',       '2024-05-03 12:07:53'),
(27.89,  '2024-05-22', 'edigitale',  'agallo',        '2024-05-22 15:33:41'),
(12.50,  '2024-06-01', 'vlogistica', 'rguerra',       '2024-06-01 10:49:17'),
(57.78,  '2024-06-16', 'vlogistica', 'mtagliaferri',  '2024-06-15 21:05:02'),
(16.90,  '2024-07-04', 'edigitale',  'lsalvatore',    '2024-07-04 08:21:36'),
(22.00,  '2024-07-19', 'vlogistica', 'mrossi',        '2024-07-19 14:37:59'),
(21.98,  '2024-08-08', 'edigitale',  'gverdi',        '2024-08-08 11:52:44'),
(19.90,  '2024-08-26', 'vlogistica', 'lbianchi',      '2024-08-25 16:18:27'),
(24.90,  '2024-09-10', 'vlogistica', 'clobello',      '2024-09-10 09:03:51'),
(31.90,  '2024-09-28', 'edigitale',  'erusso',        '2024-09-28 20:41:13'),
(13.50,  '2024-01-22', 'vlogistica', 'dmarino',       '2024-01-22 13:29:08'),
(23.98,  '2024-01-28', 'edigitale',  'fpalumbo',      '2024-01-28 17:46:35'),
(10.99,  '2024-02-05', 'vlogistica', 'gsantoro',      '2024-02-05 10:13:22'),
(44.90,  '2024-02-19', 'edigitale',  'mciccone',      '2024-02-18 15:57:44'),
(21.00,  '2024-03-03', 'vlogistica', 'abrunetti',     '2024-03-03 09:42:19'),
(38.80,  '2024-03-23', 'edigitale',  'igiordano',     '2024-03-22 18:08:33'),
(11.90,  '2024-04-08', 'vlogistica', 'cbarone',       '2024-04-08 11:24:07'),
(51.80,  '2024-04-26', 'vlogistica', 'ldonati',       '2024-04-25 14:39:51'),
(9.99,   '2024-05-07', 'edigitale',  'mquattrini',    '2024-05-07 08:55:26'),
(27.90,  '2024-05-19', 'vlogistica', 'vsergi',        '2024-05-19 16:12:48'),
(15.90,  '2024-06-03', 'edigitale',  'tneri',         '2024-06-03 12:47:03'),
(20.50,  '2024-06-20', 'vlogistica', 'rcaputo',       '2024-06-20 09:31:59'),
(62.70,  '2024-07-09', 'vlogistica', 'odesantis',     '2024-07-08 22:14:37'),
(24.90,  '2024-07-25', 'edigitale',  'bgreco',        '2024-07-25 10:06:22'),
(17.00,  '2024-08-11', 'vlogistica', 'sfabbri',       '2024-08-11 15:43:09'),
(31.88,  '2024-08-29', 'edigitale',  'ecaruso',       '2024-08-28 13:27:54'),
(13.99,  '2024-09-14', 'vlogistica', 'tviola',        '2024-09-14 08:19:41'),
(26.90,  '2024-09-30', 'edigitale',  'nardito',       '2024-09-30 17:52:16'),
(19.90,  '2024-10-16', 'vlogistica', 'pfiorentino',   '2024-10-16 11:38:45'),
(33.89,  '2024-11-03', 'edigitale',  'cgentile',      '2024-11-02 14:04:28'),
(21.98,  '2024-11-18', 'vlogistica', 'dmarino',       '2024-11-18 09:57:33'),
(14.90,  '2024-12-05', 'edigitale',  'fpalumbo',      '2024-12-05 16:22:11'),
(29.90,  '2024-12-21', 'vlogistica', 'mciccone',      '2024-12-20 12:48:57'),
(18.50,  '2025-01-08', 'edigitale',  'ldonati',       '2025-01-08 10:31:44'),
(43.80,  '2025-01-25', 'vlogistica', 'odesantis',     '2025-01-24 19:15:02'),
(12.99,  '2025-02-10', 'edigitale',  'vsergi',        '2025-02-10 08:43:37'),
(35.80,  '2025-02-26', 'vlogistica', 'igiordano',     '2025-02-25 13:59:21'),
(22.90,  '2025-03-12', 'edigitale',  'bgreco',        '2025-03-12 11:26:48'),
(15.99,  '2025-03-28', 'vlogistica', 'sfabbri',       '2025-03-28 16:07:15'),
(28.90,  '2025-04-14', 'edigitale',  'tneri',         '2025-04-14 09:53:29');

INSERT INTO Contenuto (Acquisto_Cliente, Acquisto_Data, Oggetto, Quantita) VALUES
('mrossi',       '2024-01-10 09:14:22', 'LIB-0001', 1),
('mrossi',       '2024-01-10 09:14:22', 'TAZ-0001', 1),
('gverdi',       '2024-01-15 11:03:47', 'LIB-0001', 1),
('lbianchi',     '2024-02-01 16:45:09', 'DVD-0001', 1),
('lbianchi',     '2024-02-01 16:45:09', 'LIB-0004', 1),
('sfontana',     '2024-02-14 10:22:31', 'MAG-0001', 1),
('aferrari',     '2024-02-20 14:58:03', 'DVD-0003', 1),
('aferrari',     '2024-02-20 14:58:03', 'TAZ-0003', 1),
('clobello',     '2024-03-05 08:37:55', 'MAG-0001', 1),
('clobello',     '2024-03-05 08:37:55', 'LIB-0006', 1),
('fmancini',     '2024-03-12 19:11:40', 'TAZ-0001', 1),
('erusso',       '2024-03-20 13:26:18', 'LIB-0003', 1),
('erusso',       '2024-03-20 13:26:18', 'DVD-0002', 1),
('erusso',       '2024-03-20 13:26:18', 'TAZ-0002', 1),
('pconti',       '2024-04-02 17:44:05', 'LIB-0004', 1),
('vdeluca',      '2024-04-18 09:58:29', 'DVD-0004', 1),
('nmarino',      '2024-05-03 12:07:53', 'MAG-0003', 1),
('agallo',       '2024-05-22 15:33:41', 'LIB-0007', 1),
('agallo',       '2024-05-22 15:33:41', 'TAZ-0004', 1),
('rguerra',      '2024-06-01 10:49:17', 'LIB-0002', 1),
('mtagliaferri', '2024-06-15 21:05:02', 'LIB-0005', 1),
('mtagliaferri', '2024-06-15 21:05:02', 'DVD-0008', 1),
('mtagliaferri', '2024-06-15 21:05:02', 'MAG-0002', 1),
('lsalvatore',   '2024-07-04 08:21:36', 'TAZ-0002', 1),
('mrossi',       '2024-07-19 14:37:59', 'LIB-0005', 1),
('gverdi',       '2024-08-08 11:52:44', 'DVD-0005', 1),
('gverdi',       '2024-08-08 11:52:44', 'TAZ-0003', 1),
('lbianchi',     '2024-08-25 16:18:27', 'MAG-0004', 1),
('clobello',     '2024-09-10 09:03:51', 'MAG-0001', 1),
('erusso',       '2024-09-28 20:41:13', 'LIB-0008', 1),
('erusso',       '2024-09-28 20:41:13', 'TAZ-0002', 1),
('dmarino',      '2024-01-22 13:29:08', 'LIB-0013', 1),
('fpalumbo',     '2024-01-28 17:46:35', 'DVD-0009', 1),
('fpalumbo',     '2024-01-28 17:46:35', 'TAZ-0005', 1),
('gsantoro',     '2024-02-05 10:13:22', 'DVD-0009', 1),
('mciccone',     '2024-02-18 15:57:44', 'MAG-0005', 1),
('mciccone',     '2024-02-18 15:57:44', 'LIB-0016', 1),
('abrunetti',    '2024-03-03 09:42:19', 'LIB-0014', 1),
('igiordano',    '2024-03-22 18:08:33', 'MAG-0006', 1),
('igiordano',    '2024-03-22 18:08:33', 'LIB-0015', 1),
('cbarone',      '2024-04-08 11:24:07', 'TAZ-0005', 1),
('ldonati',      '2024-04-25 14:39:51', 'LIB-0018', 1),
('ldonati',      '2024-04-25 14:39:51', 'DVD-0015', 1),
('ldonati',      '2024-04-25 14:39:51', 'MAG-0007', 1),
('mquattrini',   '2024-05-07 08:55:26', 'DVD-0011', 1),
('vsergi',       '2024-05-19 16:12:48', 'MAG-0005', 1),
('tneri',        '2024-06-03 12:47:03', 'TAZ-0007', 1),
('rcaputo',      '2024-06-20 09:31:59', 'LIB-0018', 1),
('odesantis',    '2024-07-08 22:14:37', 'LIB-0021', 1),
('odesantis',    '2024-07-08 22:14:37', 'DVD-0016', 1),
('odesantis',    '2024-07-08 22:14:37', 'MAG-0008', 1),
('bgreco',       '2024-07-25 10:06:22', 'MAG-0001', 1),
('sfabbri',      '2024-08-11 15:43:09', 'LIB-0016', 1),
('ecaruso',      '2024-08-28 13:27:54', 'DVD-0010', 1),
('ecaruso',      '2024-08-28 13:27:54', 'LIB-0013', 1),
('tviola',       '2024-09-14 08:19:41', 'DVD-0010', 1),
('nardito',      '2024-09-30 17:52:16', 'MAG-0006', 1),
('pfiorentino',  '2024-10-16 11:38:45', 'MAG-0004', 1),
('cgentile',     '2024-11-02 14:04:28', 'LIB-0017', 1),
('cgentile',     '2024-11-02 14:04:28', 'TAZ-0006', 1),
('dmarino',      '2024-11-18 09:57:33', 'DVD-0013', 1),
('dmarino',      '2024-11-18 09:57:33', 'TAZ-0008', 1),
('fpalumbo',     '2024-12-05 16:22:11', 'LIB-0002', 1),
('mciccone',     '2024-12-20 12:48:57', 'MAG-0003', 1),
('ldonati',      '2025-01-08 10:31:44', 'LIB-0021', 1),
('odesantis',    '2025-01-24 19:15:02', 'DVD-0012', 1),
('odesantis',    '2025-01-24 19:15:02', 'MAG-0005', 1),
('vsergi',       '2025-02-10 08:43:37', 'DVD-0014', 1),
('igiordano',    '2025-02-25 13:59:21', 'LIB-0019', 1),
('igiordano',    '2025-02-25 13:59:21', 'MAG-0008', 1),
('bgreco',       '2025-03-12 11:26:48', 'MAG-0006', 1),
('sfabbri',      '2025-03-28 16:07:15', 'DVD-0012', 1),
('tneri',        '2025-04-14 09:53:29', 'MAG-0007', 1);

INSERT INTO Spedizione (Stato_Spedizione, Dettagli, Via, CAP, Civico, Citta, Provincia, Nazione, Acquisto_Cliente, Acquisto_Data, Corriere) VALUES
('Consegnata',   NULL,                        'Via Roma',      '00100', '12',  'Roma',            'RM', 'Italia', 'mrossi',      '2024-01-10 09:14:22', 'BRT'),
('Consegnata',   NULL,                        'Via Milano',    '20100', '5',   'Milano',          'MI', 'Italia', 'gverdi',      '2024-01-15 11:03:47', 'GLS'),
('Consegnata',   NULL,                        'Via Napoli',    '80100', '33',  'Napoli',          'NA', 'Italia', 'lbianchi',    '2024-02-01 16:45:09', 'DHL'),
('Consegnata',   NULL,                        'Corso Torino',  '10100', '7',   'Torino',          'TO', 'Italia', 'sfontana',    '2024-02-14 10:22:31', 'Poste'),
('Consegnata',   NULL,                        'Via Bologna',   '40100', '21',  'Bologna',         'BO', 'Italia', 'aferrari',    '2024-02-20 14:58:03', 'BRT'),
('Consegnata',   NULL,                        'Via Palermo',   '90100', '8',   'Palermo',         'PA', 'Italia', 'clobello',    '2024-03-05 08:37:55', 'GLS'),
('Consegnata',   NULL,                        'Via Firenze',   '50100', '14',  'Firenze',         'FI', 'Italia', 'fmancini',    '2024-03-12 19:11:40', 'DHL'),
('Consegnata',   NULL,                        'Via Venezia',   '30100', '2',   'Venezia',         'VE', 'Italia', 'erusso',      '2024-03-20 13:26:18', 'BRT'),
('Consegnata',   NULL,                        'Viale Genova',  '16100', '18',  'Genova',          'GE', 'Italia', 'pconti',      '2024-04-02 17:44:05', 'Nexive'),
('Consegnata',   NULL,                        'Piazza Bari',   '70100', '3',   'Bari',            'BA', 'Italia', 'vdeluca',     '2024-04-18 09:58:29', 'BRT'),
('Consegnata',   NULL,                        'Via Catania',   '95100', '9',   'Catania',         'CT', 'Italia', 'nmarino',     '2024-05-03 12:07:53', 'GLS'),
('Consegnata',   NULL,                        'Via Verona',    '37100', '11',  'Verona',          'VR', 'Italia', 'agallo',      '2024-05-22 15:33:41', 'Poste'),
('Consegnata',   NULL,                        'Corso Messina', '98100', '6',   'Messina',         'ME', 'Italia', 'rguerra',     '2024-06-01 10:49:17', 'BRT'),
('Consegnata',   NULL,                        'Via Padova',    '35100', '29',  'Padova',          'PD', 'Italia', 'mtagliaferri','2024-06-15 21:05:02', 'DHL'),
('Consegnata',   NULL,                        'Via Trieste',   '34100', '17',  'Trieste',         'TS', 'Italia', 'lsalvatore',  '2024-07-04 08:21:36', 'GLS'),
('Consegnata',   NULL,                        'Via Roma',      '00100', '12',  'Roma',            'RM', 'Italia', 'mrossi',      '2024-07-19 14:37:59', 'BRT'),
('Consegnata',   NULL,                        'Via Milano',    '20100', '5',   'Milano',          'MI', 'Italia', 'gverdi',      '2024-08-08 11:52:44', 'Nexive'),
('In transito',  'Stimata: 2 giorni',         'Via Napoli',    '80100', '33',  'Napoli',          'NA', 'Italia', 'lbianchi',    '2024-08-25 16:18:27', 'DHL'),
('Consegnata',   NULL,                        'Via Palermo',   '90100', '8',   'Palermo',         'PA', 'Italia', 'clobello',    '2024-09-10 09:03:51', 'GLS'),
('In transito',  'Fermoposta su richiesta',   'Via Venezia',   '30100', '2',   'Venezia',         'VE', 'Italia', 'erusso',      '2024-09-28 20:41:13', 'BRT'),
('Consegnata',   NULL,                        'Via Lecce',     '73100', '4',   'Lecce',           'LE', 'Italia', 'dmarino',     '2024-01-22 13:29:08', 'GLS'),
('Consegnata',   NULL,                        'Via Taranto',   '74100', '19',  'Taranto',         'TA', 'Italia', 'fpalumbo',    '2024-01-28 17:46:35', 'BRT'),
('Consegnata',   NULL,                        'Corso Foggia',  '71100', '8',   'Foggia',          'FG', 'Italia', 'gsantoro',    '2024-02-05 10:13:22', 'Poste'),
('Consegnata',   NULL,                        'Via Reggio',    '89100', '3',   'Reggio Calabria', 'RC', 'Italia', 'mciccone',    '2024-02-18 15:57:44', 'DHL'),
('Consegnata',   NULL,                        'Via Perugia',   '06100', '22',  'Perugia',         'PG', 'Italia', 'abrunetti',   '2024-03-03 09:42:19', 'BRT'),
('Consegnata',   NULL,                        'Via Ancona',    '60100', '11',  'Ancona',          'AN', 'Italia', 'igiordano',   '2024-03-22 18:08:33', 'GLS'),
('Consegnata',   NULL,                        'Piazza Pescara','65100', '6',   'Pescara',         'PE', 'Italia', 'cbarone',     '2024-04-08 11:24:07', 'Nexive'),
('Consegnata',   NULL,                        'Via Livorno',   '57100', '30',  'Livorno',         'LI', 'Italia', 'ldonati',     '2024-04-25 14:39:51', 'BRT'),
('Consegnata',   NULL,                        'Via Prato',     '59100', '15',  'Prato',           'PO', 'Italia', 'mquattrini',  '2024-05-07 08:55:26', 'DHL'),
('Consegnata',   NULL,                        'Via Cosenza',   '87100', '9',   'Cosenza',         'CS', 'Italia', 'vsergi',      '2024-05-19 16:12:48', 'GLS'),
('Consegnata',   NULL,                        'Via Modena',    '41100', '44',  'Modena',          'MO', 'Italia', 'tneri',       '2024-06-03 12:47:03', 'Poste'),
('Consegnata',   NULL,                        'Via Parma',     '43100', '7',   'Parma',           'PR', 'Italia', 'rcaputo',     '2024-06-20 09:31:59', 'BRT'),
('Consegnata',   NULL,                        'Via Ravenna',   '48100', '13',  'Ravenna',         'RA', 'Italia', 'odesantis',   '2024-07-08 22:14:37', 'DHL'),
('Consegnata',   NULL,                        'Via Ferrara',   '44100', '25',  'Ferrara',         'FE', 'Italia', 'bgreco',      '2024-07-25 10:06:22', 'GLS'),
('Consegnata',   NULL,                        'Via Rimini',    '47900', '16',  'Rimini',          'RN', 'Italia', 'sfabbri',     '2024-08-11 15:43:09', 'BRT'),
('Consegnata',   NULL,                        'Via Salerno',   '84100', '5',   'Salerno',         'SA', 'Italia', 'ecaruso',     '2024-08-28 13:27:54', 'Nexive'),
('Consegnata',   NULL,                        'Via Sassari',   '07100', '20',  'Sassari',         'SS', 'Italia', 'tviola',      '2024-09-14 08:19:41', 'Poste'),
('Consegnata',   NULL,                        'Via Cagliari',  '09100', '34',  'Cagliari',        'CA', 'Italia', 'nardito',     '2024-09-30 17:52:16', 'GLS'),
('Consegnata',   NULL,                        'Corso Udine',   '33100', '12',  'Udine',           'UD', 'Italia', 'pfiorentino', '2024-10-16 11:38:45', 'BRT'),
('Consegnata',   NULL,                        'Via Aosta',     '11100', '2',   'Aosta',           'AO', 'Italia', 'cgentile',    '2024-11-02 14:04:28', 'DHL'),
('Consegnata',   NULL,                        'Via Lecce',     '73100', '4',   'Lecce',           'LE', 'Italia', 'dmarino',     '2024-11-18 09:57:33', 'GLS'),
('Consegnata',   NULL,                        'Via Taranto',   '74100', '19',  'Taranto',         'TA', 'Italia', 'fpalumbo',    '2024-12-05 16:22:11', 'BRT'),
('Consegnata',   NULL,                        'Via Reggio',    '89100', '3',   'Reggio Calabria', 'RC', 'Italia', 'mciccone',    '2024-12-20 12:48:57', 'Poste'),
('Consegnata',   NULL,                        'Via Livorno',   '57100', '30',  'Livorno',         'LI', 'Italia', 'ldonati',     '2025-01-08 10:31:44', 'DHL'),
('In transito',  'Stimata: 1 giorno',         'Via Ravenna',   '48100', '13',  'Ravenna',         'RA', 'Italia', 'odesantis',   '2025-01-24 19:15:02', 'BRT'),
('Consegnata',   NULL,                        'Via Cosenza',   '87100', '9',   'Cosenza',         'CS', 'Italia', 'vsergi',      '2025-02-10 08:43:37', 'GLS'),
('In transito',  'Tentativo fallito, ritiro', 'Via Ancona',    '60100', '11',  'Ancona',          'AN', 'Italia', 'igiordano',   '2025-02-25 13:59:21', 'Nexive'),
('Consegnata',   NULL,                        'Via Ferrara',   '44100', '25',  'Ferrara',         'FE', 'Italia', 'bgreco',      '2025-03-12 11:26:48', 'DHL'),
('In transito',  'Stimata: 3 giorni',         'Via Rimini',    '47900', '16',  'Rimini',          'RN', 'Italia', 'sfabbri',     '2025-03-28 16:07:15', 'BRT'),
('In transito',  'Stimata: 2 giorni',         'Via Modena',    '41100', '44',  'Modena',          'MO', 'Italia', 'tneri',       '2025-04-14 09:53:29', 'GLS');

-- Prenotazioni: riferite agli utenti _f (solo Fruitore)
INSERT INTO Prenotazione (Fruitore, Data, Stato, Oggetto) VALUES
('mrossi_f',     '2024-01-05', 'Confermata', 'LIB-0001'),
('gverdi_f',     '2024-01-08', 'Confermata', 'DVD-0001'),
('lbianchi_f',   '2024-01-20', 'Confermata', 'LIB-0003'),
('sfontana_f',   '2024-02-02', 'Confermata', 'DVD-0002'),
('aferrari_f',   '2024-02-15', 'Confermata', 'LIB-0005'),
('clobello_f',   '2024-03-01', 'Scaduta',    'DVD-0003'),
('fmancini_f',   '2024-03-18', 'Confermata', 'LIB-0007'),
('erusso_f',     '2024-04-05', 'Confermata', 'DVD-0004'),
('pconti_f',     '2024-04-22', 'In attesa',  'LIB-0009'),
('vdeluca_f',    '2024-05-10', 'Confermata', 'LIB-0002'),
('mrossi_f',     '2024-05-28', 'Confermata', 'DVD-0005'),
('gverdi_f',     '2024-06-14', 'Scaduta',    'LIB-0004'),
('lbianchi_f',   '2024-07-01', 'Confermata', 'DVD-0006'),
('sfontana_f',   '2024-07-19', 'In attesa',  'LIB-0010'),
('aferrari_f',   '2024-08-05', 'Confermata', 'DVD-0007'),
('clobello_f',   '2024-08-22', 'Confermata', 'LIB-0006'),
('fmancini_f',   '2024-09-08', 'Confermata', 'DVD-0008'),
('erusso_f',     '2024-09-25', 'Scaduta',    'LIB-0011'),
('pconti_f',     '2024-10-12', 'Confermata', 'LIB-0012'),
('vdeluca_f',    '2024-10-30', 'In attesa',  'DVD-0002'),
('dmarino_f',    '2024-01-15', 'Confermata', 'LIB-0013'),
('fpalumbo_f',   '2024-01-25', 'Confermata', 'DVD-0009'),
('gsantoro_f',   '2024-02-03', 'Scaduta',    'LIB-0015'),
('mciccone_f',   '2024-02-20', 'Confermata', 'DVD-0010'),
('abrunetti_f',  '2024-03-08', 'Confermata', 'LIB-0016'),
('igiordano_f',  '2024-03-25', 'Confermata', 'DVD-0011'),
('cbarone_f',    '2024-04-10', 'In attesa',  'LIB-0017'),
('ldonati_f',    '2024-04-28', 'Confermata', 'DVD-0012'),
('mquattrini_f', '2024-05-15', 'Confermata', 'LIB-0018'),
('vsergi_f',     '2024-06-01', 'Scaduta',    'DVD-0013'),
('dmarino_f',    '2024-06-18', 'Confermata', 'LIB-0019'),
('fpalumbo_f',   '2024-07-05', 'Confermata', 'DVD-0014'),
('gsantoro_f',   '2024-07-22', 'In attesa',  'LIB-0020'),
('mciccone_f',   '2024-08-08', 'Confermata', 'DVD-0015'),
('abrunetti_f',  '2024-08-25', 'Confermata', 'LIB-0021'),
('igiordano_f',  '2024-09-11', 'Scaduta',    'DVD-0016'),
('cbarone_f',    '2024-09-28', 'Confermata', 'LIB-0022'),
('ldonati_f',    '2024-10-15', 'Confermata', 'DVD-0009'),
('mquattrini_f', '2024-11-01', 'In attesa',  'LIB-0023'),
('vsergi_f',     '2024-11-18', 'Confermata', 'LIB-0024');

INSERT INTO Prestito (Prenotazione_Fruitore, Prenotazione_Data, Prenotazione_Oggetto, Data_Inizio, Data_Fine) VALUES
('mrossi_f',     '2024-01-05', 'LIB-0001', '2024-01-06', '2024-01-20'),
('gverdi_f',     '2024-01-08', 'DVD-0001', '2024-01-09', '2024-01-23'),
('lbianchi_f',   '2024-01-20', 'LIB-0003', '2024-01-21', '2024-02-04'),
('sfontana_f',   '2024-02-02', 'DVD-0002', '2024-02-03', '2024-02-17'),
('aferrari_f',   '2024-02-15', 'LIB-0005', '2024-02-16', '2024-03-01'),
('fmancini_f',   '2024-03-18', 'LIB-0007', '2024-03-19', '2024-04-02'),
('erusso_f',     '2024-04-05', 'DVD-0004', '2024-04-06', '2024-04-20'),
('vdeluca_f',    '2024-05-10', 'LIB-0002', '2024-05-11', '2024-05-25'),
('mrossi_f',     '2024-05-28', 'DVD-0005', '2024-05-29', '2024-06-12'),
('lbianchi_f',   '2024-07-01', 'DVD-0006', '2024-07-02', '2024-07-16'),
('aferrari_f',   '2024-08-05', 'DVD-0007', '2024-08-06', '2024-08-20'),
('clobello_f',   '2024-08-22', 'LIB-0006', '2024-08-23', '2024-09-06'),
('fmancini_f',   '2024-09-08', 'DVD-0008', '2024-09-09', '2024-09-23'),
('pconti_f',     '2024-10-12', 'LIB-0012', '2024-10-13', '2024-10-27'),
('dmarino_f',    '2024-01-15', 'LIB-0013', '2024-01-16', '2024-01-30'),
('fpalumbo_f',   '2024-01-25', 'DVD-0009', '2024-01-26', '2024-02-09'),
('mciccone_f',   '2024-02-20', 'DVD-0010', '2024-02-21', '2024-03-06'),
('abrunetti_f',  '2024-03-08', 'LIB-0016', '2024-03-09', '2024-03-23'),
('igiordano_f',  '2024-03-25', 'DVD-0011', '2024-03-26', '2024-04-09'),
('ldonati_f',    '2024-04-28', 'DVD-0012', '2024-04-29', '2024-05-13'),
('mquattrini_f', '2024-05-15', 'LIB-0018', '2024-05-16', '2024-05-30'),
('dmarino_f',    '2024-06-18', 'LIB-0019', '2024-06-19', '2024-07-03'),
('fpalumbo_f',   '2024-07-05', 'DVD-0014', '2024-07-06', '2024-07-20'),
('mciccone_f',   '2024-08-08', 'DVD-0015', '2024-08-09', '2024-08-23'),
('abrunetti_f',  '2024-08-25', 'LIB-0021', '2024-08-26', '2024-09-09'),
('cbarone_f',    '2024-09-28', 'LIB-0022', '2024-09-29', '2024-10-13'),
('ldonati_f',    '2024-10-15', 'DVD-0009', '2024-10-16', '2024-10-30'),
('vsergi_f',     '2024-11-18', 'LIB-0024', '2024-11-19', '2024-12-03');

-- ─────────────────────────────────────────────
-- QUERY
-- ─────────────────────────────────────────────

-- QUERY 1: Top 10 clienti per spesa totale.
SELECT U.Nome, U.Cognome, SUM(A.Totale) AS TotaleSpeso
FROM Utente U
JOIN Cliente C  ON U.Username = C.Utente
JOIN Acquisto A ON C.Utente   = A.Cliente
GROUP BY U.Username, U.Nome, U.Cognome
ORDER BY TotaleSpeso DESC
LIMIT 10;

-- QUERY 2: Fruitori con più di una prenotazione.
SELECT U.Nome, U.Cognome, COUNT(*) AS NumeroPrenotazioni
FROM Utente U
JOIN Fruitore F     ON U.Username = F.Utente
JOIN Prenotazione P ON F.Utente   = P.Fruitore
GROUP BY U.Username, U.Nome, U.Cognome
HAVING COUNT(*) > 1
ORDER BY NumeroPrenotazioni DESC;

-- QUERY 3: Top 10 corrieri per numero spedizioni e totale fatturato.
SELECT C.Nome AS Corriere,
       COUNT(S.ID_Spedizione) AS NumeroSpedizioni,
       SUM(F.Importo_Totale)  AS TotaleFatturato
FROM Corriere C
JOIN Spedizione S ON C.Nome = S.Corriere
JOIN Fattura F    ON S.Acquisto_Cliente = F.Acquisto_Cliente
                 AND S.Acquisto_Data    = F.Acquisto_Data
GROUP BY C.Nome
ORDER BY NumeroSpedizioni DESC
LIMIT 10;

-- QUERY 4: Top 10 contenuti digitali (Libri e DVD) più prenotati.
SELECT * FROM (
  SELECT O.Codice_A_Barre,
         'Libro'        AS Tipo,
         L.Autore       AS Autore_Regista,
         L.Genere_Libro AS Genere,
         COUNT(P.Oggetto) AS NumeroPrenotazioni
  FROM Oggetto O
  JOIN Libro L        ON O.Codice_A_Barre = L.Oggetto
  JOIN Prenotazione P ON O.Codice_A_Barre = P.Oggetto
  GROUP BY O.Codice_A_Barre, L.Autore, L.Genere_Libro
  UNION ALL
  SELECT O.Codice_A_Barre,
         'DVD'         AS Tipo,
         D.Regista     AS Autore_Regista,
         D.Genere_DVD  AS Genere,
         COUNT(P.Oggetto) AS NumeroPrenotazioni
  FROM Oggetto O
  JOIN DVD D          ON O.Codice_A_Barre = D.Oggetto
  JOIN Prenotazione P ON O.Codice_A_Barre = P.Oggetto
  GROUP BY O.Codice_A_Barre, D.Regista, D.Genere_DVD
) AS Risultati
ORDER BY NumeroPrenotazioni DESC
LIMIT 10;

-- QUERY 5: Top 10 venditori per importo medio fatture.
SELECT U.Nome, U.Cognome,
       COUNT(F.Numero_Fattura)        AS NumeroFatture,
       ROUND(AVG(F.Importo_Totale),2) AS MediaImporto
FROM Utente U
JOIN Venditore V ON U.Username = V.Utente
JOIN Fattura F   ON V.Utente   = F.Venditore
GROUP BY U.Username, U.Nome, U.Cognome
ORDER BY MediaImporto DESC
LIMIT 10;

-- ─────────────────────────────────────────────
-- INDICI
-- ─────────────────────────────────────────────
-- Si ottimizza la QUERY 2 (2 JOIN, 1 GROUP BY, 1 HAVING su Prenotazione).
-- Due indici HASH sulle colonne di equi-join:
CREATE INDEX idx_prenotazione_fruitore
    ON Prenotazione USING HASH (Fruitore);

CREATE INDEX idx_fruitore_utente
    ON Fruitore USING HASH (Utente);
-- L'indice B+ Tree su Prenotazione(Fruitore) non viene creato esplicitamente:
-- PostgreSQL genera già automaticamente un indice B+ Tree sulla chiave primaria
-- (Fruitore, Data, Oggetto), che include Fruitore come primo campo e supporta
-- sia il JOIN che il GROUP BY senza ordinamento aggiuntivo.