function convData = convertedData(serialObj,app)
    
    % Pobierz dane z serialObj
    [gps_data, acc_data, gps_coordinate] = recivedData(serialObj, app);
    app.TextArea.Value{end+1} = 'Zbieranie danych zakończone.';

    app.TextArea.Value{end+1} ='--------------------------------------------------------------------';

    app.TextArea.Value{end+1} ='Przetwarzanie danych.';
    
    % Konwersja danych
    convData = conversion(gps_data, acc_data, gps_coordinate);
    app.TextArea.Value{end+1} ='Przetwarzanie danych zakończone.';

end