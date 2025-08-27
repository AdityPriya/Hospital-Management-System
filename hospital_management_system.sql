CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;

 -- patients Table
 
CREATE TABLE IF NOT EXISTS patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  gender ENUM('M','F','Other'),
  date_of_birth DATE,
  phone VARCHAR(15),
  address VARCHAR(255)
);

-- Doctors Table
CREATE TABLE IF NOT EXISTS doctors (
  doctor_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  specialty VARCHAR(100),
  phone VARCHAR(15),
  email VARCHAR(100)
);

-- Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
  appointment_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT,
  doctor_id INT,
  scheduled_at DATETIME,
  reason VARCHAR(200),
  status ENUM('Booked','CheckedIn','Completed','Cancelled') DEFAULT 'Booked',
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- Medical Records Table
CREATE TABLE IF NOT EXISTS medical_records (
  record_id INT AUTO_INCREMENT PRIMARY KEY,
  patient_id INT,
  doctor_id INT,
  diagnosis VARCHAR(200),
  treatment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
  FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE
);

-- Rooms Table
CREATE TABLE IF NOT EXISTS rooms (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    room_type VARCHAR(50),
    daily_rate DECIMAL(10,2)
);

-- Admissions Table
CREATE TABLE IF NOT EXISTS admissions (
    admission_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    room_id INT,
    admit_datetime DATETIME,
    discharge_datetime DATETIME,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (room_id) REFERENCES rooms(room_id)
);

-- Bills Table
CREATE TABLE IF NOT EXISTS bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    admission_id INT,
    bill_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
);

-- Bill Items Table
CREATE TABLE IF NOT EXISTS bill_items (
    bill_item_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT,
    item_type VARCHAR(50),
    description VARCHAR(200),
    qty INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
);

-- 3. Insert Sample Data

-- Patients
INSERT INTO patients(full_name, gender, date_of_birth, phone, address)
VALUES 
('Rahul Sharma','M','1990-05-12','9876543210','Delhi'),
('Priya Verma','F','1995-08-20','9123456789','Kolkata');

-- Doctors
INSERT INTO doctors(full_name, specialty, phone, email)
VALUES
('Dr. Mehta','Cardiologist','9000000001','mehta@hospital.com'),
('Dr. Sen','Neurologist','9000000002','sen@hospital.com');

-- Rooms
INSERT INTO rooms(room_type, daily_rate)
VALUES ('General', 1000.00), ('ICU', 5000.00);

-- Admissions
INSERT INTO admissions(patient_id, room_id, admit_datetime)
VALUES (1, 1, '2025-08-30 09:00:00');

-- 4. Stored Procedure: Book Appointment
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_book_appointment $$
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_scheduled_at DATETIME,
    IN p_reason VARCHAR(200)
)
BEGIN
    DECLARE v_conflict INT DEFAULT 0;

    -- Check if doctor already has appointment at same time
    SELECT COUNT(*) INTO v_conflict
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND scheduled_at = p_scheduled_at
      AND status IN ('Booked','CheckedIn');

    -- If conflict exists, throw error
    IF v_conflict > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Time slot already booked for this doctor.';
    END IF;

    -- Insert new appointment
    INSERT INTO appointments(patient_id, doctor_id, scheduled_at, reason)
    VALUES (p_patient_id, p_doctor_id, p_scheduled_at, p_reason);

    -- Return the new appointment ID
    SELECT LAST_INSERT_ID() AS new_appointment_id;
END $$
DELIMITER ;

-- 5. Test Appointment Procedure
CALL sp_book_appointment(1, 1, '2025-08-31 11:00:00', 'Routine Check');

-- 6. Create Bill Totals View
CREATE OR REPLACE VIEW v_bill_totals AS
SELECT b.bill_id,
       b.patient_id,
       SUM(bi.qty * bi.unit_price) AS total_amount
FROM bills b
JOIN bill_items bi ON bi.bill_id = b.bill_id
GROUP BY b.bill_id, b.patient_id;

-- 7. Check appointments
SELECT * FROM appointments;



CREATE TABLE medicines (
    medicine_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    stock INT,
    unit_price DECIMAL(10,2)
);


CREATE TABLE lab_tests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT,
    test_name VARCHAR(100),
    result VARCHAR(255),
    test_date DATETIME,
    FOREIGN KEY(patient_id) REFERENCES patients(patient_id)
);


INSERT INTO patients(full_name, gender, date_of_birth, phone, address)
VALUES 
('Rahul Sharma','M','1990-05-12','9876543210','Delhi'),
('Priya Verma','F','1995-08-20','9123456789','Kolkata'),
('Ankit Jain','M','1988-03-15','9988776655','Mumbai'),
('Sneha Roy','F','1992-11-05','9122334455','Bangalore');


INSERT INTO doctors(full_name, specialty, phone, email)
VALUES
('Dr. Mehta','Cardiologist','9000000001','mehta@hospital.com'),
('Dr. Sen','Neurologist','9000000002','sen@hospital.com'),
('Dr. Kapoor','Orthopedic','9000000003','kapoor@hospital.com'),
('Dr. Iyer','Pediatrician','9000000004','iyer@hospital.com');


INSERT INTO rooms(room_type, daily_rate)
VALUES 
('General', 1000.00),
('ICU', 5000.00),
('Semi-Private', 2500.00),
('Private', 4000.00);

INSERT INTO admissions(patient_id, room_id, admit_datetime)
VALUES 
(1, 1, '2025-08-30 09:00:00'),
(2, 2, '2025-08-30 10:30:00'),
(3, 3, '2025-08-31 08:45:00');

-- Patient 1 with Dr. Mehta
CALL sp_book_appointment(1, 1, '2025-08-31 19:00:00', 'Routine Check');

-- Patient 2 with Dr. Sensp_book_appointment
CALL sp_book_appointment(2, 2, '2025-08-31 12:30:00', 'Headache');

-- Patient 3 with Dr. Kapoor
CALL sp_book_appointment(3, 3, '2025-08-31 14:00:00', 'Knee Pain');

-- Patient 4 with Dr. Iyer
CALL sp_book_appointment(4, 4, '2025-08-31 09:30:00', 'Child Fever');


INSERT INTO bills(patient_id, admission_id)
VALUES 
(1, 1),
(2, 2),
(3, 3);

INSERT INTO bill_items(bill_id, item_type, description, qty, unit_price)
VALUES 
(1, 'RoomCharge', 'General Room', 2, 1000.00),
(1, 'DoctorFee', 'Consulting Fee', 1, 500.00),
(2, 'RoomCharge', 'ICU Room', 1, 5000.00),
(2, 'DoctorFee', 'Consulting Fee', 1, 700.00),
(3, 'RoomCharge', 'Semi-Private', 3, 2500.00),
(3, 'DoctorFee', 'Consulting Fee', 1, 600.00);


-- Check all appointments
SELECT * FROM appointments;

-- Check all bills
SELECT * FROM bills;

-- Check bill items
SELECT * FROM bill_items;

-- View total bill amounts
SELECT * FROM v_bill_totals;
