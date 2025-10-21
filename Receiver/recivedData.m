function [gps_data, acc_data, gps_coordinate] = recivedData(serialObj, app)
    % Główna część programu
    try
        % Wysyłanie komend inicjalizacyjnych
        app.TextArea.Value{end+1} ='Konfiguracja LoRa:';
        send_command('AT', serialObj); % Wysłanie komendy AT
        pause(1);
        send_command('AT+MODE=TEST', serialObj); % Ustawienie trybu TEST
        pause(1);

        % Wysyłanie komendy do zbierania danych
        send_command('AT+TEST=RXLRPKT', serialObj);

        app.TextArea.Value{end+1} ='--------------------------------------------------------------------';

        % Odbieranie danych
        [gps_data, acc_data, gps_coordinate] = listen_data(serialObj);


    catch ME
        app.TextArea.Value{end+1} = sprintf('Błąd podczas otwierania portu: %s\n', ME.message);
        app.TextArea.Value{end+1} ='--------------------------------------------------------------------';

    end


    % Funkcja do wysyłania komendy
    function send_command(command, serialObj)
        try
            writeline(serialObj, command); % Wysyłanie komendy
            pause(1); % Czas na przetworzenie komendy
            atCom = readline(serialObj);
            app.TextArea.Value{end+1} = sprintf('Odebrano: %s', atCom);
        catch ME
            app.TextArea.Value{end+1} = sprintf('Błąd: %s\n', ME.message);
            app.TextArea.Value{end+1} ='--------------------------------------------------------------------';
        end
    end

    % Funkcja do nasłuchiwania danych
    function [gps_data, acc_data, gps_coordinate] = listen_data(serialObj)
        app.TextArea.Value{end+1} ='Zbieranie danych:';
        gps_data = []; % Macierz do przechowywania danych GPS [czas, dane]
        acc_data = []; % Macierz do przechowywania danych akcelerometru [czas, dane]
        gps_coordinate = []; % Macierz do przechowywania danych współrzędnych GPS [czas, dane]
        start_time = []; % Zmienna do przechowywania czasu startowego
        last_received_time = tic; % Pomiar czasu od ostatniego odebrania danych

        while true
            if serialObj.NumBytesAvailable > 0 % Sprawdź, czy są dostępne dane
                data = readline(serialObj); % Odczytaj linię danych

                % Ustaw czas początkowy przy odbiorze pierwszej wiadomości
                if isempty(start_time)
                    start_time = tic;
                end

                % Sprawdź, czy linia zawiera dane w ""
                expr = '".+"'; % Wyrażenie regularne do dopasowania zawartości w cudzysłowie
                match = regexp(data, expr, 'match');

                if ~isempty(match)
                    data_to_save = strrep(match{1}, '"', ''); % Usuń cudzysłowy
                    formatted_data = insert_hyphens(data_to_save); % Dodaj myślniki do danych
                    current_time = toc(start_time);

                % Rozróżnienie typów danych
                if length(data_to_save) == 4 && all(isstrprop(data_to_save, 'xdigit'))
                    gps_data = [gps_data; current_time, string(formatted_data)];
                    app.TextArea.Value{end+1} = sprintf('Czas: %.2f s, Dane GPS: %s', current_time, formatted_data);
                elseif length(data_to_save) == 10 && all(isstrprop(data_to_save, 'xdigit'))
                    gps_coordinate = [gps_coordinate; current_time, string(formatted_data)];
                    app.TextArea.Value{end+1} = sprintf('Czas: %.2f s, Współrzędne GPS: %s', current_time, formatted_data);
                else
                    acc_data = [acc_data; current_time, string(formatted_data)];
                    app.TextArea.Value{end+1} = sprintf('Czas: %.2f s, Dane akcelerometru: %s', current_time, formatted_data);
                end

                    % Aktualizuj czas ostatniego odbioru
                    last_received_time = tic;
                end
            end

            % Jeśli brak danych przez 10 sekundy, zakończ nasłuchiwanie
            if toc(last_received_time) > 10
                app.TextArea.Value{end+1} ='Brak danych przez 10 sekund. Zamykanie połączenia...';
                break;
            end

            pause(0.1); % Krótkie opóźnienie, aby nie zablokować CPU
        end

        

    end

    % Funkcja do formatowania danych z myślnikami co 4 znaki
    function formatted_data = insert_hyphens(data)
        if length(data) == 10
            formatted_data = regexprep(data, '(.{5})', '$1-'); % Wstaw myślniki co pięć znaków
            if endsWith(formatted_data, '-') % Usuń końcowy myślnik, jeśli jest
                formatted_data = formatted_data(1:end-1);
            end
        else
            formatted_data = regexprep(data, '(.{4})', '$1-'); % Wstaw myślniki co cztery znaki
            if endsWith(formatted_data, '-') % Usuń końcowy myślnik, jeśli jest
                formatted_data = formatted_data(1:end-1);
            end
        end
    end
end
