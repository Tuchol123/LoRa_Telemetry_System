function convData = conversion(gps_data, acc_data, gps_coordinate)
    % Inicjalizacja struktur do przechowywania skonwertowanych danych
    convGPS = []; % Macierz do przechowywania skonwertowanych danych GPS
    convAcc = []; % Macierz do przechowywania skonwertowanych danych akcelerometru
    convCoordinates = []; % Macierz do przechowywania skonwertowanych współrzędnych

    % Przetwarzanie danych GPS
    for i = 1:size(gps_data, 1)
        % Pobierz czas i dane z bieżącego wiersza
        time_value = str2double(gps_data{i, 1});
        data_value = gps_data{i, 2};

        % Podział na składowe
        hex_components = split(data_value, '-');
        
        if length(hex_components) >= 1
            % Pobranie pierwszych 4 znaków z pierwszej składowej
            first_four_chars = hex_components{1}(1:4);
            
            % Konwersja tylko pierwszych 4 znaków z szesnastkowej na dziesiętną z uwzględnieniem znaku
            value = hex2dec_signed(first_four_chars);
            
            % Dodanie przeskalowanej wartości do macierzy wynikowej dla GPS
            if value == 0
                converted_value = round(value);
            else
                converted_value = round(value/100); % Przeskalowanie przez 100
            end
            convGPS = [convGPS; time_value, converted_value];
        end
    end

    % Przetwarzanie danych akcelerometru
    for i = 1:size(acc_data, 1)
        % Pobierz czas i dane z bieżącego wiersza
        time_value = str2double(acc_data{i, 1});
        data_value = acc_data{i, 2};

        % Podział na składowe
        hex_components = split(data_value, '-');
        
        if length(hex_components) >= 2
            % Pobranie pierwszych 4 znaków z pierwszej składowej
            first_four_chars = hex_components{1}(1:4);
            
            % Konwersja tylko pierwszych 4 znaków z szesnastkowej na dziesiętną z uwzględnieniem znaku
            value = hex2dec_signed(first_four_chars);
            
            if value == 0
                converted_value = value;
            else
                converted_value = value/100; % Przeskalowanie przez 100
            end
            % Dodanie przeskalowanej wartości do macierzy wynikowej dla akcelerometru
            convAcc = [convAcc; time_value, converted_value]; % Przeskalowanie przez 100
        end
    end

    % Przetwarzanie danych współrzędnych GPS
    for i = 1:size(gps_coordinate, 1)
        % Pobierz czas i dane z bieżącego wiersza
        time_value = str2double(gps_coordinate{i, 1});
        coord_value = gps_coordinate{i, 2};

        % Podział współrzędnych GPS na składowe
        hex_components = split(coord_value, '-');
        
        if length(hex_components) >= 2
            % Konwersja obu składowych (przykład dla długości i szerokości geograficznej)
            latitude_hex = hex_components{1};
            longitude_hex = hex_components{2};
            
            % Konwersja składowych na dziesiętne ze znakiem
            latitude = hex2dec(latitude_hex) / 10000; % Skala współrzędnych
            longitude = hex2dec(longitude_hex) / 10000; % Skala współrzędnych
            
            % Dodanie przeskalowanych współrzędnych do macierzy wynikowej
            convCoordinates = [convCoordinates; time_value, latitude, longitude];
        end
    end

    % Zapisanie wyników do struktury wyjściowej
    convData.convGPS = convGPS;
    convData.convAcc = convAcc;
    convData.convCoordinates = convCoordinates;

    % Funkcja do konwersji liczby szesnastkowej na dziesiętną ze znakiem
    function decimal_value = hex2dec_signed(hex_string)
        decimal_value = hex2dec(hex_string);
        % Sprawdzenie, czy liczba jest ujemna (jeśli najstarszy bit jest ustawiony)
        if decimal_value >= 2^(4*length(hex_string)-1)
            decimal_value = decimal_value - 2^(4*length(hex_string));
        end
    end
end
