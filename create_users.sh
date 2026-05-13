#!/bin/bash

# 1. Säkerställ att skriptet körs av root eller relevant rättigheter. När EUID inte är = 0 så är det inte root för att ID 0 brukar vara alltid root
if [ $EUID -ne 0 ]; then
    echo "Du måste vara root eller ha rättigheter för att köra skriptet."
    exit 1
fi

# 2. Kontrollera att något namn fylls i. Annars så är ju "räkningen" = 0
if [ $# -eq 0 ]; then
    echo "Skriv in namn så här: ./$0 Kalle Anna Bert...... "
    exit 1
fi

# 3. Loopa/gå igenom alla inskickade namn i "påsen" $@ och använd username som variablen för att hämta namnen från "påsen"
for username in "$@"; do

    # 4. Kontrollera om användaren redan finns. Tystar echo/stdout och errors/stderr till genom att slänga in det i "svarta hålet" /dev/null
    if ! id "$username" > /dev/null 2>&1; then
        echo "Skapar användare: $username"

        # Skapa användare med hemkatalog
        useradd -m "$username"

        # Skapa undermapparna. Får ej glömma parent så det inte haltar hela loopen för att skriva ut error.
        mkdir -p /home/$username/{Documents,Downloads,Work}

        # 5. Skapar välkomst-filen. Först med "rubriken" och sedan tillägger den en radbrytning till filen. På slutet så lägger den till den sista echo till filen.
        echo "Välkommen $username till servern!" > /home/$username/welcome.txt
        echo "" >> /home/$username/welcome.txt
        echo "Här är dina kollegor på systemet:" >> /home/$username/welcome.txt
        
        # Hämta alla användarnamn men filtrera bort sig självt (T.ex. Anna ser inte sig själv i filen). Märkte även att cut tog med alla grupper, e.g. root, sudo osv.
        awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | grep -v "$username" >> /home/$username/welcome.txt

        # 6. Sätt rättigheter och ägarskap, gör användaren ägare till allt i sin hemkatalog. Alltså användare:grupp, t.ex. Anna:Anna. Får ej glömma rekursivt för att få med alla undermappar också!
        chown -R "$username":"$username" /home/$username

        # Sätt privata rättigheter på mappar och välkomstfil. Ställer en "hänglås" så att användare bestämmer över mapparna och filerna inuti förutom welcome.txt.
        chmod 700 /home/$username/{Documents,Downloads,Work}
        chmod 600 /home/$username/welcome.txt

        echo "Användaren $username är nu redo."
    else
        echo "Hoppar över: Användaren $username finns redan."
    fi

done

echo "Scriptet är klar nu!"
