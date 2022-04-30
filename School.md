# School
#### Aliaksandr Skvarniuk, Andrii Kovryhin, Maksym Tur
## Tematyka:
### Baza danych szkoły podstawowej.

## Cel:
#### Zrobić bazę dannych która będzie w stanie zamienić w szkole sposób przechowywania danych z zapisanych na papieru na ich elektroniczną  wersje. Zautomatyzować operacje dotyczące użycia tych dannych.

### Opis schematu. Napotkane problemy i sposoby ich rozwiązania:
Baza przechowywa trzy główne bloki dannych:
1. Podstawowa informacja o uczniach i nauczycielach
   * pupils
   * marks
   * teachers
2. Grupy zajęciowe
   * subjects
   * groups
3. Biblioteka
   * book_types
   * books
   * books_histori

Oraz ich powiązania i dopełnienia.
Uczni(pupils) są w klasach(classes), które są rozbite na grupy(groups).
Te grupy odnoszą się do jakiegoś z przedmiotów(subjects). 
Oni są nieobchodne dlatego, że w jedym klasie u jednego przedmiotu może kilka grup zajęciowych.

Jasne, że znając grupę musimy mieć dostęp do listy jej człąków to samo dla uczniow, dlatego pojawiła się tablica pupil_groups.
W jednej grupie mogą być tylko uczni z jednej klasy dlatego w groups pojawiła się krotka class_id.

Bloki 1 i 2 najwięcej przecinają się w tablice lessons.
W jednej grupie w ten sam czas nie mogą być zaplanowane dwa zajęcia.

W tablicy marks mamy jako klucz głuwny parę (pupil_id, lesson_id), ale my dodaliśmy jeszcze id, dlatego że to będzie potrzebne w dalszych krokach projektu.
Będą zaimplimentowane funkcji zliczania średniej oceny, i to nie jest tak łatwo zrobić, jak na to wygłąda.
Ona może być zliczana wędług różnych kombinacji różnych parametrów, naprzykład średnia ocena po zadanej grupie, w takim roku i inne.

Ostatnim blockiem jest biblioteka, która składa się z zapisów wzięcia/zwracania książek oraz samich książek.
Jasne, że musimy mieć informację o tym, kto kontaktuje z książką. Mieliśmy taki problem, że nie wszystkie książki mogą brać uczni, bo oni są tylko dla nauczucieli, rozwiązaniem tego występuje  user_permission(0 – dla wszystkich, 1 – dla nauczycieli).
Ale nadal był otwarty problem tego, do której tablicy zwracać się kiedy mamy jakieś id człowieka.
Jako rozwiązanie pojawiły się dwie krotki: pupil_id, teacher_id, które wskazują na odpowiednia tablicy.
Jedna z nich musi być równa NULL, inna – wypełniona.   

U każdej książki jest swój typ oraz stan, wędług kturego wydają się uczniam książki (im więcej średnia ocena ucznia, tym w lepszym stanie książkę on otrzymuje).

### Następne kroki:
#### Zaimplimentować funkcję opisane wcześniej, wypełnić tablicy dannymi. 



