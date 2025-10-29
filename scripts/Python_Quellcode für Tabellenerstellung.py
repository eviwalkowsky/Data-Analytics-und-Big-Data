import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime
import os

fake = Faker()

# Zielordner
output_path = "/Users/Pfad"
os.makedirs(output_path, exist_ok=True)

# Tabellen-Definitionen mit exakt den gewünschten Variablen
tables = {
    "CM": ["Record_ID", "Timestamp", "Machine_ID", "Product_ID", "Error_Code", "Anomaly_Flag",
           "Confidence_Level", "Sensor_Temperature", "Sensor_Vibration", "Sensor_Pressure",
           "Downtime_Start", "Downtime_End", "Repair_Duration_Minutes", "Performance_Score"],
    
    "I40": ["Record_ID", "Timestamp", "Machine_ID", "Product_ID", "Operator_Notes", "Predictive_Action",
            "Production_Status", "Sensor_Data_JSON", "Control_Signal", "Deviation_From_Setpoint",
            "Setpoint", "Energy_Consumption", "Temperature_Avg", "Pressure_Avg", "Vibration_Avg"],
    
    "PF": ["Record_ID", "Timestamp", "Product_ID", "Production_Line_ID", "Shift_ID",
           "Order_Quantity", "Units_Produced", "Units_Defective", "Resource_Usage", "Demand_Forecast",
           "Production_Time", "Downtime_Minutes"],
    
    "PM": ["Record_ID", "Timestamp", "Machine_ID", "Product_ID", "Maintenance_Type", "Maintenance_Date",
           "Maintenance_Costs", "Operation_Hours", "Failure_Flag", "Sensor_Temperature", "Sensor_Vibration",
           "Sensor_Pressure", "Time_Since_Last_Maintenance"],
    
    "YIELD": ["Record_ID", "Timestamp", "Machine_ID", "Product_ID", "Input_Material", "Output_Product",
              "Production_Line_ID", "Throughput_Rate", "Yield_Percentage", "Cycle_Time", "Defect_Rate", "Downtime_Minutes"]
}

# Funktion zum Erstellen von Daten
def generate_data(table_name, columns, start_date, end_date, record_start, record_end):
    n = record_end - record_start + 1
    df = pd.DataFrame()
    df['Record_ID'] = np.arange(record_start, record_end + 1)
    
    # Timestamps
    start = datetime.strptime(start_date, "%d.%m.%Y")
    end = datetime.strptime(end_date, "%d.%m.%Y")
    df['Timestamp'] = [int((start + (end - start) * np.random.rand()).strftime("%Y%m%d")) for _ in range(n)]
    
    # Machine_ID / Product_ID
    if "Machine_ID" in columns:
        df['Machine_ID'] = [f"M{np.random.randint(1,10):02}" for _ in range(n)]
    if "Product_ID" in columns:
        df['Product_ID'] = [f"P{np.random.randint(1,20):03}" for _ in range(n)]
    
    # CHAR Spalten
    char_cols = [c for c in columns if c not in df.columns]
    for col in char_cols:
        df[col] = [fake.word() for _ in range(n)]
    
    # NUMERIC Spalten
    if "Sensor_Vibration" in columns:
        df['Sensor_Vibration'] = np.round(np.random.uniform(0, 20, n), 2)
    if "Sensor_Temperature" in columns:
        df['Sensor_Temperature'] = np.round(np.random.uniform(0, 150, n), 1)
    if "Sensor_Pressure" in columns:
        df['Sensor_Pressure'] = np.round(np.random.uniform(0, 500, n), 1)
    if "Anomaly_Flag" in columns:
        df['Anomaly_Flag'] = np.random.randint(0,2,n)
    if "Confidence_Level" in columns:
        df['Confidence_Level'] = np.random.randint(80,101,n)
    if "Performance_Score" in columns:
        df['Performance_Score'] = np.round(np.random.uniform(50,100,n),1)
    if "Repair_Duration_Minutes" in columns:
        df['Repair_Duration_Minutes'] = np.round(np.random.uniform(10,300,n),1)
    if "Downtime_Start" in columns and "Downtime_End" in columns:
        start_offsets = np.random.randint(0, 50, n)
        durations = np.random.randint(1, 10, n)
        df['Downtime_Start'] = start_offsets
        df['Downtime_End'] = start_offsets + durations
    if "Sensor_Value" in columns:
        df['Sensor_Value'] = np.round(np.random.uniform(0, 1000,n),1)
    if "Temperature_Avg" in columns:
        df['Temperature_Avg'] = np.round(np.random.uniform(-40,100,n),1)
    if "Pressure_Avg" in columns:
        df['Pressure_Avg'] = np.round(np.random.uniform(0,500,n),1)
    if "Vibration_Avg" in columns:
        df['Vibration_Avg'] = np.round(np.random.uniform(0,20,n),1)
    if "Control_Signal" in columns:
        df['Control_Signal'] = np.round(np.random.uniform(0,100,n),1)
    if "Deviation_From_Setpoint" in columns:
        df['Deviation_From_Setpoint'] = np.round(np.random.uniform(-10,10,n),2)
    if "Setpoint" in columns:
        df['Setpoint'] = np.round(np.random.uniform(0,100,n),1)
    if "Energy_Consumption" in columns:
        df['Energy_Consumption'] = np.round(np.random.uniform(0,1000,n),1)
    if "Pressure" in columns:
        df['Pressure'] = np.round(np.random.uniform(0,500,n),1)
    if "Efficiency" in columns:
        df['Efficiency'] = np.round(np.random.uniform(60,100,n),1)
    if "Operation_Hours" in columns:
        df['Operation_Hours'] = np.round(np.random.uniform(0,3000,n),1)
    if "Vibration" in columns:
        df['Vibration'] = np.round(np.random.uniform(0,20,n),2)
    if "Failure_Flag" in columns:
        df['Failure_Flag'] = np.random.randint(0,2,n)
    if "Units_Defective" in columns:
        df['Units_Defective'] = np.random.randint(0,50,n)
    if "Units_Produced" in columns:
        df['Units_Produced'] = np.random.randint(50,1000,n)
    if "Demand_Forecast" in columns:
        df['Demand_Forecast'] = np.random.randint(100,1000,n)
    if "Production_Time" in columns:
        df['Production_Time'] = np.round(np.random.uniform(1,24,n),2)
    if "Resource_Usage" in columns:
        df['Resource_Usage'] = np.round(np.random.uniform(0,100,n),2)
    if "Time_Since_Last_Maintenance" in columns:
        df['Time_Since_Last_Maintenance'] = np.round(np.random.uniform(1,1000,n),1)
    if "Maintenance_Costs" in columns:
        df['Maintenance_Costs'] = np.round(np.random.uniform(100,10000,n),1)
    if "Cycle_Time" in columns:
        df['Cycle_Time'] = np.round(np.random.uniform(1,10,n),2)
    if "Defect_Rate" in columns:
        df['Defect_Rate'] = np.round(np.random.uniform(0,5,n),2)
    if "Throughput_Rate" in columns:
        df['Throughput_Rate'] = np.round(np.random.uniform(10,1000,n),1)
    if "Downtime_Minutes" in columns:
        df['Downtime_Minutes'] = np.round(np.random.uniform(0,500,n),1)
    if "Output_Product" in columns:
        df['Output_Product'] = np.round(np.random.uniform(10,1000,n),1)
    
    return df[columns]

# Daten erstellen und speichern
for table_name, cols in tables.items():
    # Historic CSV
    df_historic = generate_data(table_name, cols, "01.01.2020", "31.12.2024", 1, 1000)
    df_historic.to_csv(os.path.join(output_path, f"{table_name}_HISTORIC.csv"), index=False)
    
    # Current Excel
    df_current = generate_data(table_name, cols, "01.01.2025", datetime.now().strftime("%d.%m.%Y"), 1001, 1200)
    excel_file = os.path.join(output_path, f"{table_name}_CURRENT.xlsx")
    with pd.ExcelWriter(excel_file, engine='xlsxwriter') as writer:
        df_current.to_excel(writer, sheet_name=table_name, index=False)
