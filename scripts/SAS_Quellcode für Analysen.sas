/* 1_Import. xlsx und csv Tabellen */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* proc import für .xlsx */
proc import datafile='/home/u64360402/Pumpwerk/CM_CURRENT.xlsx'
    out=Pumpwerk.CM_CURRENT
    dbms=xlsx replace;
    sheet='CM';
run;

proc import datafile='/home/u64360402/Pumpwerk/PF_CURRENT.xlsx'
    out=Pumpwerk.PF_CURRENT
    dbms=xlsx replace;
    sheet='PF';
run;

proc import datafile='/home/u64360402/Pumpwerk/I40_CURRENT.xlsx'
    out=Pumpwerk.I40_CURRENT
    dbms=xlsx replace;
    sheet='I40';
run;

proc import datafile='/home/u64360402/Pumpwerk/PM_CURRENT.xlsx'
    out=Pumpwerk.PM_Current
    dbms=xlsx replace;
    sheet='PM';
run;

proc import datafile='/home/u64360402/Pumpwerk/YIELD_CURRENT.xlsx'
    out=Pumpwerk.YIELD_CURRENT
    dbms=xlsx replace;
    sheet='YIELD';
run;

/* proc import %macro für .csv */
%let csv_tables = PM_HISTORIC CM_HISTORIC PF_HISTORIC YIELD_HISTORIC I40_HISTORIC;
%macro import_csv(tablename);
    /* Import der Originaldaten */
    proc import datafile="/home/u64360402/Pumpwerk/&tablename..csv"
        out=Pumpwerk.&tablename
        dbms=csv replace;
        getnames=yes;
    run;
%mend;

%import_csv(PM_HISTORIC)
%import_csv(CM_HISTORIC)
%import_csv(PF_HISTORIC)
%import_csv(YIELD_HISTORIC)
%import_csv(I40_HISTORIC)



/* 2_Header von csv. Tabellen gesplittet */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* .csv -  Headerzeile in einzelne Variablen aufgeteilen */
proc import datafile="//home/u64360402/Pumpwerk/CM_HISTORIC.csv"
    out=Pumpwerk.CM_HISTORIC
    dbms=csv
    replace;
    getnames=yes;          
    delimiter=',';
run;

proc import datafile="//home/u64360402/Pumpwerk/I40_HISTORIC.csv"
    out=Pumpwerk.I40_HISTORIC
    dbms=csv
    replace;
    getnames=yes;          
    delimiter=',';
run;

proc import datafile="//home/u64360402/Pumpwerk/PF_HISTORIC.csv"
    out=Pumpwerk.PF_HISTORIC
    dbms=csv
    replace;
    getnames=yes;          
    delimiter=',';
run;

proc import datafile="//home/u64360402/Pumpwerk/PM_HISTORIC.csv"
    out=Pumpwerk.PM_HISTORIC
    dbms=csv
    replace;
    getnames=yes;          
    delimiter=',';
run;

proc import datafile="//home/u64360402/Pumpwerk/YIELD_HISTORIC.csv"
    out=Pumpwerk.YIELD_HISTORIC
    dbms=csv
    replace;
    getnames=yes;          
    delimiter=',';
run;



/* 3_Information über Variablen aller Tabellen */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* Information über Variablen aller Tabellen */
proc sql;
    create table column_info as
    select 
        libname,
        memname as Table_Name,
        name as Column_Name,
        length(name) as ColumnName_Length, 
        type as Column_Type,
        length as Column_Length,            
        case 
            when type='char' then length    
            when type='num' then 8        
            else .
        end as Column_Width
    from dictionary.columns
    where libname='PUMPWERK'                
    order by memname, name;
quit;

proc print data=column_info noobs;
run;


/* 4_CHAR Variablen auf 200 Zeichen erweitern */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* CHAR Variablen auf 200 Zeichen erweitern */
%macro expand_char(lib=, newlen=200);

    /* alle Tabellen in der Library finden */
    proc sql noprint;
        select memname into :tables separated by ' '
        from dictionary.tables
        where libname=upcase("&lib");
    quit;

    %let ntables=%sysfunc(countw(&tables));

    /* jede Tabelle prüfen */
    %do i=1 %to &ntables;
        %let tbl=%scan(&tables, &i);

        /* alle CHAR Variablen der Tabelle ermitteln */
        proc sql noprint;
            select name into :charvars separated by ' '
            from dictionary.columns
            where libname=upcase("&lib") 
              and memname=upcase("&tbl")
              and type='char';
        quit;

        %if "&charvars" ne "" %then %do;

            /* DATA Step: CHAR-Variablen erweitern */
            data &lib..&tbl;
                length
                %do j=1 %to %sysfunc(countw(&charvars));
                    %scan(&charvars, &j) $&newlen
                %end;
                ;
                set &lib..&tbl;
            run;

        %end;

    %end;

%mend expand_char;

%expand_char(lib=Pumpwerk, newlen=200);



/* 5_Vollständige Prüfung aller Tabellen */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* VOLLSTÄNDIGE PRÜFUNG ALLER TABELLEN */

/* NUMERIC CHECKS */
/* Fehlende Werte, Wertebereiche, logische Abhängigkeiten */ 
%macro check_num(table);
    data CHK_&table._NUM;
        set PUMPWERK.&table;
        length Issue $200;
        Issue='';

        /* alle numerischen Variablen ermitteln */
        array nums _numeric_;
        do over nums;
            if missing(nums) then Issue=catx(';',Issue,'Missing '||vname(nums));
        end;

        /* tabellenspezifische Range-Checks */
        %if &table=CM_CURRENT or &table=CM_HISTORIC %then %do;
            if Sensor_Temperature <0 or Sensor_Temperature >150 then Issue=catx(';',Issue,'Temperature out of range');
            if Sensor_Vibration <0 or Sensor_Vibration >20 then Issue=catx(';',Issue,'Vibration out of range');
            if Sensor_Pressure <0 then Issue=catx(';',Issue,'Pressure negative');
            if Anomaly_Flag not in (0,1) then Issue=catx(';',Issue,'Anomaly_Flag invalid');
        %end;
        %else %if &table=YIELD_CURRENT or &table=YIELD_HISTORIC %then %do;
            if Yield_Value <0 or Yield_Value >100 then Issue=catx(';',Issue,'Yield_Value out of range');
            if Units <0 then Issue=catx(';',Issue,'Units negative');
        %end;
        %else %if &table=PM_CURRENT or &table=PM_HISTORIC %then %do;
            if Failure_Flag not in (0,1) then Issue=catx(';',Issue,'Failure_Flag invalid');
        %end;
        %else %if &table=I40_CURRENT or &table=I40_HISTORIC %then %do;
            if Pressure <0 then Issue=catx(';',Issue,'Pressure negative');
            if Temperature < -40 or Temperature > 100 then Issue=catx(';',Issue,'Temperature out of expected range');
        %end;
        %else %if &table=PF_CURRENT or &table=PF_HISTORIC %then %do;
            if Pressure <0 then Issue=catx(';',Issue,'Pressure negative');
            if Efficiency <0 or Efficiency>100 then Issue=catx(';',Issue,'Efficiency out of range');
        %end;

        /* logische Abhängigkeiten (falls Variablen existieren) */
        if (exist('Downtime_Start'n) and exist('Downtime_End'n)) then do;
            if ('Downtime_Start'n ne . and 'Downtime_End'n ne .) and 'Downtime_Start'n > 'Downtime_End'n then 
                Issue=catx(';',Issue,'Downtime_Start after Downtime_End');
        end;

        if exist('Maintenance_Date'n) then do;
            if 'Maintenance_Date'n ne . and 'Maintenance_Date'n > today() then 
                Issue=catx(';',Issue,'Maintenance_Date in future');
        end;

        if exist('Failure_Flag') and exist('Sensor_Vibration') then do;
            if Failure_Flag=1 and Sensor_Vibration <5 then 
                Issue=catx(';',Issue,'Failure_Flag=1 but low Vibration');
        end;

        /* Ausgabe, wenn Issue gefunden wurde */
        if Issue ne '';
    run;
%mend;

/* CHARACTER CHECKS */
/* Fehlende Werte, führende/nachfolgenen Leerzeichen, Sonderzeichen */
%macro check_char(table);
    data CHK_&table._CHAR;
        set PUMPWERK.&table;
        length Issue $200;
        Issue='';

        array chars _character_;
        do over chars;
            /* Missing prüfen, optional befüllte Felder bleiben unmarkiert */
            if missing(chars) and chars ne '' then Issue=catx(';',Issue,'Missing '||vname(chars));
            else if strip(chars) ne chars then Issue=catx(';',Issue,'Leading/Trailing space '||vname(chars));
            if prxmatch('/[^[:alnum:][:punct:] ]/',chars) then Issue=catx(';',Issue,'Special chars in '||vname(chars));
        end;

        if Issue ne '';
    run;
%mend;

/* DUPLICATE CHECKS */
/* Doppelte Record_ID, doppelte Record_ID+Timestamp */
%macro check_dups(table);
    proc sort data=PUMPWERK.&table out=CHK_&table._DUPS nodupkey dupout=CHK_&table._DUPS_OUT;
        by Record_ID;
    run;

    proc sort data=PUMPWERK.&table out=CHK_&table._DUPS_MT nodupkey dupout=CHK_&table._DUPS_MT_OUT;
        by Record_ID Timestamp;
    run;
%mend;

/* SUMMARY STATISTICS */
/* PROC MEANS für numerische Felder */
%macro check_means(table);
    proc means data=PUMPWERK.&table n min max mean std nmiss;
        var _numeric_;
        output out=CHK_&table._SUMMARY;
    run;
%mend;

/* DATENQUALITÄTSPRÜFUNG */
/* Führt alle Prüf-Makros für jede Tabelle automatisch aus */
%let tables = CM_CURRENT CM_HISTORIC I40_CURRENT I40_HISTORIC 
              PF_CURRENT PF_HISTORIC PM_CURRENT PM_HISTORIC 
              YIELD_CURRENT YIELD_HISTORIC;

%macro check_all;
    %do i=1 %to %sysfunc(countw(&tables));
        %let table = %scan(&tables, &i);
        %check_num(&table);
        %check_char(&table);
        %check_dups(&table);
        %check_means(&table);
    %end;
%mend;

%check_all;



/* 6-SET-Anweisung _Historic und _Current Tabellen zusammengeführt */

/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* CM: Historic + Current */
data PUMPWERK.CM_ALL;
    set PUMPWERK.CM_HISTORIC
        PUMPWERK.CM_CURRENT;
run;

/* I40: Historic + Current */
data PUMPWERK.I40_ALL;
    set PUMPWERK.I40_HISTORIC
        PUMPWERK.I40_CURRENT;
run;

/* PF: Historic + Current */
data PUMPWERK.PF_ALL;
    set PUMPWERK.PF_HISTORIC
        PUMPWERK.PF_CURRENT;
run;

/* PM: Historic + Current */
data PUMPWERK.PM_ALL;
    set PUMPWERK.PM_HISTORIC
        PUMPWERK.PM_CURRENT;
run;

/* YIELD: Historic + Current */
data PUMPWERK.YIELD_ALL;
    set PUMPWERK.YIELD_HISTORIC
        PUMPWERK.YIELD_CURRENT;
run;




/*7_Dezimalwerte auf 0.1 runden */


/* libname defieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* Dezimalstellen auf 0.1 konvertieren */

/* CM Tabellen */
data CM_ALL_mod;
    set PUMPWERK.CM_ALL;
    
    /* Char-Variablen beibehalten */
    retain Machine_ID Product_ID Error_Code;
    
    /* Numerische Variablen runden */
    Anomaly_Flag = round(Anomaly_Flag, 0.1);
    Confidence_Level = round(Confidence_Level, 0.1);
    Downtime_End = round(Downtime_End, 0.1);
    Downtime_Start = round(Downtime_Start, 0.1);
    Performance_Score = round(Performance_Score, 0.1);
    Record_ID = round(Record_ID, 0.1);
    Repair_Duration_Minutes = round(Repair_Duration_Minutes, 0.1);
    Sensor_Pressure = round(Sensor_Pressure, 0.1);
    Sensor_Temperature = round(Sensor_Temperature, 0.1);
    Sensor_Vibration = round(Sensor_Vibration, 0.1);
    Timestamp = round(Timestamp, 0.1);
run;

/* I40 Tabellen */
data I40_ALL_mod;
    set PUMPWERK.I40_ALL;
    retain Machine_ID Product_ID Operator_Notes Predictive_Action Production_Status Sensor_Data_JSON;

    Control_Signal = round(Control_Signal, 0.1);
    Deviation_From_Setpoint = round(Deviation_From_Setpoint, 0.1);
    Energy_Consumption = round(Energy_Consumption, 0.1);
    Pressure_Avg = round(Pressure_Avg, 0.1);
    Setpoint = round(Setpoint, 0.1);
    Temperature_Avg = round(Temperature_Avg, 0.1);
    Vibration_Avg = round(Vibration_Avg, 0.1);
    Record_ID = round(Record_ID, 0.1);
    Timestamp = round(Timestamp, 0.1);
run;

/* PF Tabellen */
data PF_ALL_mod;
    set PUMPWERK.PF_ALL;
    retain Product_ID Production_Line_ID Shift_ID Order_Quantity;

    Demand_Forecast = round(Demand_Forecast, 0.1);
    Downtime_Minutes = round(Downtime_Minutes, 0.1);
    Production_Time = round(Production_Time, 0.1);
    Record_ID = round(Record_ID, 0.1);
    Resource_Usage = round(Resource_Usage, 0.1);
    Units_Defective = round(Units_Defective, 0.1);
    Units_Produced = round(Units_Produced, 0.1);
    Timestamp = round(Timestamp, 0.1);
run;

/* PM Tabellen */
data PM_ALL_mod;
    set PUMPWERK.PM_ALL;
    retain Machine_ID Product_ID Maintenance_Type Maintenance_Date;
    
    Failure_Flag = round(Failure_Flag, 0.1);
    Maintenance_Costs = round(Maintenance_Costs, 0.1);
    Operation_Hours = round(Operation_Hours, 0.1);
    Sensor_Pressure = round(Sensor_Pressure, 0.1);
    Sensor_Temperature = round(Sensor_Temperature, 0.1);
    Sensor_Vibration = round(Sensor_Vibration, 0.1);
    Time_Since_Last_Maintenance = round(Time_Since_Last_Maintenance, 0.1);
    Record_ID = round(Record_ID, 0.1);
    Timestamp = round(Timestamp, 0.1);
run;

/* YIELD Tabellen */
data YIELD_ALL_mod;
    set PUMPWERK.YIELD_ALL;
    retain Machine_ID Product_ID Input_Material Output_Product Production_Line_ID Throughput_Rate Yield_Percentage;

    Cycle_Time = round(Cycle_Time, 0.1);
    Defect_Rate = round(Defect_Rate, 0.1);
    Downtime_Minutes = round(Downtime_Minutes, 0.1);
    Output_Product = round(Output_Product, 0.1);
    Record_ID = round(Record_ID, 0.1);
    Throughput_Rate = round(Throughput_Rate, 0.1);
    Timestamp = round(Timestamp, 0.1);
run;



/* 8_Datentypen NUM_CHAR anpassen */

/* libname definieren */
libname Pumpwerk '/home/u64360402/Pumpwerk';

/* CM Tabellen */
data CM_ALL_num;
    set PUMPWERK.CM_ALL;
    retain Machine_ID Product_ID Error_Code;

    array chars _character_;
    do i = 1 to dim(chars);
        if vname(chars[i]) not in ('Machine_ID','Product_ID','Error_Code') then do;
            tmp = input(chars[i], best32.);
            chars[i] = tmp;
        end;
    end;
    drop i tmp;
run;

/* I40 Tabellen */
data I40_ALL_num;
    set PUMPWERK.I40_ALL;
    retain Machine_ID Product_ID Operator_Notes Predictive_Action Production_Status Sensor_Data_JSON;

    array chars _character_;
    do i = 1 to dim(chars);
        if vname(chars[i]) not in ('Machine_ID','Product_ID','Operator_Notes','Predictive_Action','Production_Status','Sensor_Data_JSON') then do;
            tmp = input(chars[i], best32.);
            chars[i] = tmp;
        end;
    end;
    drop i tmp;
run;

/* PF Tabellen */
data PF_ALL_num;
    set PUMPWERK.PF_ALL;
    retain Product_ID Production_Line_ID Shift_ID Order_Quantity;

    array chars _character_;
    do i = 1 to dim(chars);
        if vname(chars[i]) not in ('Product_ID','Production_Line_ID','Shift_ID','Order_Quantity') then do;
            tmp = input(chars[i], best32.);
            chars[i] = tmp;
        end;
    end;
    drop i tmp;
run;

/* PM Tabellen */
data PM_ALL_num;
    set PUMPWERK.PM_ALL;
    retain Machine_ID Product_ID Maintenance_Type Maintenance_Date;

    array chars _character_;
    do i = 1 to dim(chars);
        if vname(chars[i]) not in ('Machine_ID','Product_ID','Maintenance_Type','Maintenance_Date') then do;
            tmp = input(chars[i], best32.);
            chars[i] = tmp;
        end;
    end;
    drop i tmp;
run;

/* YIELD Tabellen */
data YIELD_ALL_num;
    set PUMPWERK.YIELD_ALL;
    retain Machine_ID Product_ID Input_Material Output_Product Production_Line_ID Throughput_Rate Yield_Percentage;

    array chars _character_;
    do i = 1 to dim(chars);
        if vname(chars[i]) not in ('Machine_ID','Product_ID','Input_Material','Output_Product','Production_Line_ID','Throughput_Rate','Yield_Percentage') then do;
            tmp = input(chars[i], best32.);
            chars[i] = tmp;
        end;
    end;
    drop i tmp;
run;



/* 9_Datenanalyse und Visualisierungen */

/* libname defieren */
libname Prototyp '/home/u64360402/Prototyp';

/* Grafikeinstellungen */
ods graphics on / width=745.44px;



/* Predictive Maintenance (PM) - Tabelle: PM_ALL */

proc sgscatter data=Prototyp.PM_ALL;
  plot Sensor_Vibration*Operation_Hours / group=Failure_Flag markerattrs=(symbol=circlefilled size=10);
  title "Streudiagramm: Betriebsstunden vs. Sensorschwingung nach Ausfallstatus";
run;

proc sgplot data=Prototyp.PM_ALL;
  vbox Sensor_Temperature / category=Failure_Flag;
  title "Boxplot: Sensortemperatur nach Ausfallstatus";
run;

proc sgplot data=Prototyp.PM_ALL;
  heatmapparm x=Machine_ID y=Sensor_Temperature colorresponse=Sensor_Vibration /
    colormodel=(lightblue lightred);
  title "Heatmap: Sensorschwingung über Maschinen und Sensortemperatur";
run;

proc means data=Prototyp.PM_ALL mean std min max n;
  class Failure_Flag;
  var Sensor_Temperature Sensor_Vibration Sensor_Pressure;
  title "Deskriptive Statistik: Sensorwerte nach Ausfallstatus";
run;


/* Condition Monitoring (CM) - Tabelle: CM_ALL */

proc sgscatter data=Prototyp.CM_ALL;
  plot Sensor_Temperature*Sensor_Vibration / group=Anomaly_Flag;
  title "Streudiagramm: Sensortemperatur vs. Sensorschwingung nach Anomalie-Status";
run;

proc sgplot data=Prototyp.CM_ALL;
  histogram Sensor_Vibration / group=Anomaly_Flag transparency=0.5 nbins=30;
  density Sensor_Vibration / type=kernel group=Anomaly_Flag;
  title "Histogramm: Verteilung der Sensorschwingung nach Anomalie-Status";
run;

/* Clusteranalyse Maschinenverhalten (k-Means 3 Cluster) */
proc fastclus data=Prototyp.CM_ALL out=CM_Cluster maxclusters=3;
  var Sensor_Temperature Sensor_Vibration Sensor_Pressure;
run;

/* 2D Streudiagramm Cluster vs Sensorwerte */
proc sgscatter data=CM_Cluster;
  plot Sensor_Temperature*Sensor_Vibration / group=cluster;
  title "Streudiagramm: Sensorwerte nach Clusterzugehörigkeit";
run;


/* Production Forecasting (PF) - Tabelle: PF_ALL */

/* Top 5 Produktionslinien nach Units_Produced */
proc sql outobs=5;
    create table PF_Top as
    select Production_Line_ID, sum(Units_Produced) as Total_Units
    from PUMPWERK.PF_ALL
    group by Production_Line_ID
    order by Total_Units desc;
quit;

/* Haupttabelle auf Top 5 filtern */
proc sql;
    create table PF_ALL_Plot as
    select a.*
    from PUMPWERK.PF_ALL as a
    inner join PF_Top as b
    on a.Production_Line_ID = b.Production_Line_ID;
quit;

/* Labels für Top 5 Grafiken erstellen */
data PF_ALL_Plot;
    set PF_ALL_Plot;
    length ProdLine_Label $10;
    retain counter 0;
    if _N_ = 1 then counter = 0;
    if not missing(Production_Line_ID) then counter + 1;
    ProdLine_Label = cats('Linie', counter);
run;

proc sgscatter data=PF_ALL_Plot;
    plot Units_Produced*Order_Quantity / group=ProdLine_Label;
    title "Streudiagramm: Produktionsmenge vs. Auftragsmenge (Top 5 Linien)";
run;

/* Streudiagramm Units_Produced vs Order_Quantity nach Production_Line_ID */
proc sgscatter data=Prototyp.PF_ALL;
  plot Units_Produced*Order_Quantity / group=Production_Line_ID;
  title "Streudiagramm: Produktionsmenge vs. Auftragsmenge";
run;

proc sgplot data=PF_ALL_Plot;
    vbox Demand_Forecast / category=ProdLine_Label;
    title "Boxplot: Prognostizierte Nachfrage nach Produktionslinie (Top 5)";
run;

proc sgplot data=Prototyp.PF_ALL;
  vbox Demand_Forecast / category=Production_Line_ID;
  title "Boxplot: Prognostizierte Nachfrage nach Produktionslinie";
run;

proc sgplot data=PF_ALL_Plot;
    vbar ProdLine_Label / response=Units_Produced stat=sum;
    vbar ProdLine_Label / response=Demand_Forecast stat=sum transparency=0.5;
    title "Balkendiagramm: Tatsächliche vs. prognostizierte Produktionsmengen (Top 5)";
run;

proc sgplot data=Prototyp.PF_ALL;
  vbar Production_Line_ID / response=Units_Produced stat=sum;
  vbar Production_Line_ID / response=Demand_Forecast stat=sum transparency=0.5;
  title "Balkendiagramm: Tatsächliche vs. prognostizierte Produktionsmengen";
run;


/* Yield Optimization (YIELD) - Tabelle: YIELD_ALL */

/* Top 5 Produktionslinien nach Output_Product */
proc sql outobs=5;
    create table YIELD_Top as
    select Production_Line_ID, sum(Output_Product) as Total_Output
    from PUMPWERK.YIELD_ALL
    group by Production_Line_ID
    order by Total_Output desc;
quit;

/* Haupttabelle auf Top 5 filtern */
proc sql;
    create table YIELD_ALL_Plot as
    select a.*
    from PUMPWERK.YIELD_ALL as a
    inner join YIELD_Top as b
    on a.Production_Line_ID = b.Production_Line_ID;
quit;

/* Labels für Grafiken (Top5) */
data YIELD_ALL_Plot;
    set YIELD_ALL_Plot;
    length ProdLine_Label $10;
    retain counter 0;
    if _N_ = 1 then counter = 0;
    if not missing(Production_Line_ID) then counter + 1;
    ProdLine_Label = cats('Linie', counter);
run;

proc sgplot data=YIELD_ALL_Plot;
    scatter x=Input_Material y=Output_Product / group=ProdLine_Label markerattrs=(symbol=circlefilled size=10);
    title "Streudiagramm: Output vs. Input-Material nach Produktionslinie (Top 5)";
run;

proc sgplot data=Prototyp.YIELD_ALL;
  scatter x=Input_Material y=Output_Product / group=Production_Line_ID markerattrs=(symbol=circlefilled size=10);
  title "Streudiagramm: Output vs. Input-Material nach Produktionslinie";
run;

/* Boxplot Yield_Percentage nach Production_Line_ID */
proc sgplot data=Prototyp.YIELD_ALL;
  vbox Yield_Percentage / category=Production_Line_ID;
  title "Boxplot: Ertragsprozentsatz nach Produktionslinie";
run;



/* Industrie 4.0 / Digital Twin (I40) - Tabelle: I40_ALL */

/* Top 5 Predictive_Action nach Vibration_Avg */
proc sql outobs=5;
    create table I40_Top as
    select Predictive_Action, mean(Vibration_Avg) as Avg_Vibration
    from PUMPWERK.I40_ALL
    group by Predictive_Action
    order by Avg_Vibration desc;
quit;

/* Haupttabelle auf Top 5 filtern */
proc sql;
    create table I40_ALL_Plot as
    select a.*
    from PUMPWERK.I40_ALL as a
    inner join I40_Top as b
    on a.Predictive_Action = b.Predictive_Action;
quit;

/* Labels für Grafiken (Top5) */
data I40_ALL_Plot;
    set I40_ALL_Plot;
    length Action_Label $10;
    retain counter 0;
    if _N_ = 1 then counter = 0;
    if not missing(Predictive_Action) then counter + 1;
    Action_Label = cats('Aktion', counter);
run;

proc sgscatter data=I40_ALL_Plot;
    plot Temperature_Avg*Vibration_Avg / group=Action_Label;
    title "Durchschnittstemperatur vs. Durchschnittsvibration (Top 5 Aktionen)";
run;

proc sgscatter data=Prototyp.I40_ALL;
  plot Temperature_Avg*Vibration_Avg / group=Predictive_Action;
  title "Streudiagramm: Durchschnittstemperatur vs. Durchschnittsvibration";
run;

proc sgplot data=Prototyp.I40_ALL;
  loess x=Timestamp y=Energy_Consumption / smooth=0.5 lineattrs=(color=red thickness=2);
  title "Liniendiagramm(Verlauf): Energieverbrauch über die Zeit (Loess-Kurve)";
run;

ods graphics off;



