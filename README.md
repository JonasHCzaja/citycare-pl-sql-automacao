# CityCare - PL/SQL Automation

## 📊 About the Project

CityCare is a **PL/SQL-based automation system** designed to improve urban management processes by integrating **database automation** techniques such as **stored procedures, triggers, and functions**.  

The project focuses on **monitoring urban occurrences, environmental conditions, and waste management**, ensuring efficiency through automated data handling and notifications.

## 🚀 Features

- **Database Modeling (ER Diagram)** representing Smart City operations.
- **PL/SQL Scripts** for creating and managing database tables.
- **Automated processes** for monitoring occurrences, environmental alerts, and waste collection.
- **Stored Procedures and Triggers** for automating key urban management functions.

## 🛠️ Technologies Used

- **Oracle Database** for data storage and processing.
- **PL/SQL** for procedural programming within the database.
- **SQL Developer** or any Oracle-compatible database management tool.

## ⚡ How to Run the Project

### Prerequisites

- **Oracle Database** installed and configured.
- **SQL Developer** or another SQL execution environment.

### Steps

1. Clone the repository:

    ```sh
    git clone https://github.com/your-user/citycare-plsql-automation.git
    cd citycare-plsql-automation
    ```

2. Open **SQL Developer** (or any Oracle SQL tool) and connect to the database.

3. Execute the **citycare-automacao.sql** script to create tables and automation:

    ```sql
    @citycare-automacao.sql
    ```

4. Verify that the tables and automation processes were created successfully.

## 📌 Automated Processes

### 1️⃣ Address Verification & Auto-Fill
- Ensures that **location data** is properly registered before inserting records into other related tables.
- **Stored Procedure: `sp_verificar_ou_registrar_localizacao`** automatically inserts new locations if they don’t exist.

### 2️⃣ Automatic Alerts for Occurrences
- **Trigger:** `tr_alerta_ocorrencia`
- **Functionality:** Automatically **notifies all users** in the same neighborhood when a **new occurrence is registered**.

### 3️⃣ Restricted Status Updates for Occurrences
- **Trigger:** `tr_verificar_permissao_atualizacao`
- **Functionality:** Ensures that **only the user who reported the issue or an admin** can **update the occurrence status**.

### 4️⃣ Waste Collection Notifications
- **Trigger:** `tr_notifica_coleta_lixo`
- **Functionality:** Sends **automated notifications** to users about their **scheduled waste collection day**.

## 🎓 Academic Context

This project was developed as part of the **Analysis and Systems Development** course at **FIAP**. The main objective is to explore **database automation studies** using **PL/SQL** and how **triggers, procedures, and functions** can improve **urban management and Smart City operations**.

### **Topics Covered**
- **Database Modeling (ER Diagram)** for Smart City applications.
- **PL/SQL Triggers, Procedures, and Functions** for automating processes.
- **Event-Driven Database Programming** to optimize urban services.
- **SQL Queries for Data Processing and Monitoring**.

---

Developed by **JonasHCzaja**.
