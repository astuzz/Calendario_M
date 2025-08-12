let
 
    DataInicio = #date(1900, 1, 1),
    DataFim = #date(Date.Year(DateTime.LocalNow())+3, 12, 31),
    Dias = Duration.Days(DataFim-DataInicio)+1,
    Duracao = List.Dates(DataInicio, Dias, #duration(1,0,0,0)),


    #"Convertido para Tabela" = Table.FromList(Duracao, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Coluna Data" = Table.RenameColumns(#"Convertido para Tabela",{{"Column1", "Data"}}),
    #"Tipo Alterado" = Table.TransformColumnTypes(#"Coluna Data",{{"Data", type date}}),

    #"Tempo" = Table.AddColumn(#"Tipo Alterado" , "Tempo", each 
        let
            hoje = DateTime.Date(DateTime.LocalNow()),
            data = [Data],
            ontem = Date.AddDays(hoje, -1),
            amanha = Date.AddDays(hoje, 1),
            semanaPassada = Date.AddWeeks((hoje), -1),
            mesPassado =  Date.IsInPreviousMonth(hoje),
            anoPassado = Date.IsInPreviousYear(data) 
 
        in
            if [Data] = hoje then "Hoje"
            else if [Data] = ontem then "Ontem" 
            else if [Data] = amanha then "Amanhã" 
            else if Date.IsInCurrentWeek(data) then "Esta Semana"
            else if Date.IsInPreviousWeek(data) then "Semana Passada"
            else if Date.IsInNextWeek(data) then "Próxima Semana"
            else if Date.IsInCurrentMonth(data) then "Este Mês"
            else if Date.IsInPreviousMonth(data) then "Mês Passado"
            else if Date.IsInNextMonth(data) then "Próximo Mês"
            else if Date.IsInCurrentYear(data) then "Este Ano"
            else if Date.IsInPreviousYear(data) then "Ano Passado"
            else if data > hoje then "Futuro"
            else if data < hoje then "Passado"
            else "",
            type text 
    ),
 
    #"Ano" = Table.AddColumn(Tempo, "Ano", each Date.Year([Data]), Int64.Type),
    #"Linhas Classificadas" = Table.Sort(Ano,{{"Data", Order.Descending}}),
    #"Mês" = Table.AddColumn(#"Linhas Classificadas", "Mês", each Date.Month([Data]), Int64.Type),
    #"Dia" = Table.AddColumn(Mês, "Dia", each Date.Day([Data]), Int64.Type),
    #"Dias no Mês" = Table.AddColumn(#"Dia", "Dias no Mês", each Date.DaysInMonth([Data]), Int64.Type),

    #"Nome do Mês" = Table.AddColumn(#"Dias no Mês", "Nome do Mês", each Date.MonthName([Data]), type text),
    #"Mês Abreviado 3" = Table.AddColumn(#"Nome do Mês", "Mês Abreviado 3", each Text.Start([Nome do Mês], 3), type text),
    #"Mês Abreviado 1" = Table.AddColumn(#"Mês Abreviado 3", "Mês Abreviado 1", each Text.Start([Nome do Mês], 1), type text),
 
    #"Início do Mês" = Table.AddColumn(#"Mês Abreviado 1", "Início do Mês", each Date.StartOfMonth([Data]), type date),
    #"Fim do Mês" = Table.AddColumn(#"Início do Mês", "Fim do Mês", each Date.EndOfMonth([Data]), type date),
   
    #"Trimestre" = Table.AddColumn(#"Fim do Mês", "Trimestre", each Date.QuarterOfYear([Data]), Int64.Type),
    #"Trimestre Abreviado" = Table.AddColumn(#"Trimestre", "Trimestre Abreviado", each Text.Combine({Text.From([Trimestre], "pt-BR"), " Tri"}), type text),
    #"Início do Trimestre" = Table.AddColumn(#"Trimestre Abreviado", "Início do Trimestre", each Date.StartOfQuarter([Data]), type date),
    #"Fim do Trimestre" = Table.AddColumn(#"Início do Trimestre", "Fim do Trimestre", each Date.EndOfQuarter([Início do Trimestre]), type date),

    #"Semana do Ano" = Table.AddColumn(#"Fim do Trimestre", "Semana do Ano", each Date.WeekOfYear([Fim do Trimestre]), Int64.Type),
    #"Semana do Mês" = Table.AddColumn(#"Semana do Ano", "Semana do Mês", each Date.WeekOfMonth([Data]), Int64.Type),
    #"Início da Semana" = Table.AddColumn(#"Semana do Mês", "Início da Semana", each Date.StartOfWeek([Data]), type date),
    #"Fim da Semana" = Table.AddColumn(#"Início da Semana", "Fim da Semana", each Date.EndOfWeek([Data]), type date),
   
    
    #"Data AnoMesDia" = 
        Table.AddColumn(
            #"Fim da Semana", 
            "Data AnoMesDia", 
            each Text.Combine({
                Date.ToText([Data], "yyyy"), 
                if Date.Month([Data]) >=1 and Date.Month([Data]) <10  
                    then "0"&Date.ToText([Data], "%M")
                else
                    Date.ToText([Data], "%M"), 
                Date.ToText([Data], "dd")}
            ), type text
        ),
 
    #"Dia da Semana" = Table.AddColumn(#"Data AnoMesDia", "Dia da Semana", each Date.DayOfWeek([Data]), Int64.Type),
    #"Nome do Dia" = Table.AddColumn(#"Dia da Semana", "Nome do Dia", each Date.DayOfWeekName([Data]), type text),
    #"Nome Dia 3" = Table.AddColumn(#"Nome do Dia", "Nome Dia 3", each Text.Start([Nome do Dia], 3), type text),
    #"Nome Dia 1" = Table.AddColumn(#"Nome Dia 3", "Nome Dia 1", each Text.Start([Nome do Dia], 1), type text),
    
    
    #"EFimdeSemana" = 
        Table.AddColumn(
            #"Nome Dia 1", 
            "EFimdeSemana", 
                each if ([Nome do Dia] = "domingo" or [Nome do Dia] = "sábado")
                    then "Fim de Semana" 
                else "Dia de Semana",
                type text
        ),
    
    
    #"Dia/Mes" = Table.AddColumn(#"EFimdeSemana", "Dia/Mes", each Text.Combine({Date.ToText([Data], "dd"), "/", Text.Proper(Date.ToText([Data], "MMM"))}), type text),
    #"MesAno" = Table.AddColumn(#"Dia/Mes", "Mês/Ano", each Text.Combine({Text.Proper(Date.ToText([Data], "MMM")), "/", Date.ToText([Data], "yyyy")}), type text),
    
    Semestre = 
        Table.AddColumn( 
            #"MesAno",
            "Semestre",
            each if Date.Month([Data]) <= 6 
                then "1º Semestre" 
            else "2º Semestre",
        type text
        ),

    Bimestre = 
        Table.AddColumn(
            #"Semestre",
            "Bimestre",
            each Number.ToText(Number.RoundUp(Date.Month([Data]) / 2)) & "º Bimestre",
            type text
        ),

    AnoBissexto = 
        Table.AddColumn(
            #"Semestre",
            "AnoBissexto",
            each if Date.IsLeapYear([Data]) then "Sim" else "Não",
            type text
        ),

    #"Estação Hemisfério Norte" = 
        Table.AddColumn(
             AnoBissexto, 
            "Estação Hemisfério Norte", 
            each 
                let
                    data = [Data],
                    dia = Date.Day(data),
                    mes = Date.Month(data)
                in
                    if (mes = 3 and dia >= 21) or (mes = 4) or (mes = 5) or (mes = 6 and dia <= 20) then "Primavera"
                    else if (mes = 6 and dia >= 21) or (mes = 7) or (mes = 8) or (mes = 9 and dia <= 20) then "Verão"
                    else if (mes = 9 and dia >= 21) or (mes = 10) or (mes = 11) or (mes = 12 and dia <= 20) then "Outono"
                    else if (mes = 12 and dia >= 21) or (mes = 1) or (mes = 2) or (mes = 3 and dia <= 20) then "Inverno"
                    else null,
            type text
        ),

    
    #"Estação Hemisfério Sul" = 
        Table.AddColumn(
            #"Estação Hemisfério Norte", 
            "Estação Hemisfério Sul", 
            each 
                let
                    data = [Data],
                    dia = Date.Day(data),
                    mes = Date.Month(data)
                in
                    if (mes = 12 and dia >= 21) or (mes = 1) or (mes = 2) or (mes = 3 and dia <= 20) then "Verão"
                    else if (mes = 3 and dia >= 21) or (mes = 4) or (mes = 5) or (mes = 6 and dia <= 20) then "Outono"
                    else if (mes = 6 and dia >= 21) or (mes = 7) or (mes = 8) or (mes = 9 and dia <= 20) then "Inverno"
                    else if (mes = 9 and dia >= 21) or (mes = 10) or (mes = 11) or (mes = 12 and dia <= 20) then "Primavera"
                    else null,
            type text
        ),

    #"Fim" = #"Estação Hemisfério Sul"
 
in
    #"Fim"