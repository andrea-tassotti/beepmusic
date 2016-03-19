# beepmusic
An experiment for music with beep command.


Vogliamo fornire un nuovo strumento per la Beep Music (vedi http://www.nerdammer.it/2016/02/20/diversamente-arte-prima-parte/), che sia semplice e piú”musicale” possibile.

Proponiamo di scrivere in un semplice file testo una nota per riga (come un “rullo musicale”), espressa con altezza, durata naturale e modificatori, tre campi separati da carattere colon (:). Questo file testo sarà la nostra partitura che un software (che andremo a costruire) provvederà a convertire in una sequenze di comandi beep.

Esistono sistemi di Music Engraving che si basano su file testo molto semplice (vedi abc),
quindi non si consideri banale questo metodo: solo prototipale.

L’altezza sarà espressa in notazione anglosassone e con estensione come dettata anche dallo standard MIDI dalla MMA (da C-2 a G8, ossia dal Do ben 2 ottave sotto la nota piú bassa del pianoforte, fino a 127 semitoni sopra).
La durata sarà espressa in termini di divisione musicale, esprimendo la componente a denominatore. Come modificatori saranno supportati il punto (singolo, doppio e triplo, e i gruppi (irregolari) espressi da un semplice numero.
Le pause saranno espresse da note con altezza “P”, con durata e modificatori come per le note.

E’ evidente che in questo modo la durata e posizione delle note nel tempo musicale é garantita dalla divisione del tempo tra note e pause (come é nelle notazione classica e come é pure per il comando beep.

A completare la sintassi introduciamo indicazioni sulla divisione con il metadato tsig (indicata in modo canonico con una frazione), ed indicazione sul tempo (velocità di esecuzione), con un numero che esprima i bpm (beat for measure) ossia il numero di pulsazioni (note di lunghezza indicate dal denominatore delle tsig: per un 3/4 una nota di 1/4) al minuto.
Questi parametri altro non fanno che produrre il rapporto tra le durate di note e pause in termini di tempo assoluto (secondi o frazionamenti).

Se volessimo realizzare un metronomo per una divisione 4/4 avremo:

A5:4:
A4:4:
A4:4:
A4:4:

Ma questo andrebbe bene se il generatore di toni fosse di natura impulsiva e le note poste all’inizio dei quarti della misura decadessero in ampiezza prima di esaurire la loro durata (caso tipico di una partitura MIDI per un drum kick).

Questo non é quasi mai valido in generale, e non é assolutamete vero nel caso di beep ché si comporta come un generatore di tono ideale (potendo assumere altezza e durata arbitrari).

Per questo la giusta partitura potrebbe essere:

A5:16:
A4:16:
A4:16:
A4:16:

Dato che questo è poco intuitivo per un musicista, introduciamo un meccanismo di “umanizzazione” indicando nella “partitura” i portamenti “legato” (comportamanto naturale) e “staccato” (meccanismo per emulare suoni di natura impulsiva). Questo sintatticamente verrà collocato all’interno di una riga di commento. La riga di commento potrà essere inoltre utilizzata per indicare l’inizio della “misura” (o battuta). Questo potrà essere d’ausilio nella verifica (anche automatica) della trascrizione.

