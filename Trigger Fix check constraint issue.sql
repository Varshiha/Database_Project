--Write a database trigger that ensures when a new billing record is inserted into the Billing table; the corresponding pat_balance in the Patient table is automatically updated. 
--Specifically, the value in the bill_balance column of the inserted record must be added to the existing balance of the associated patient. 

--You may need to modify your schema to support this requirement, such as adding a pat_balance column to the PATIENT table. 
--Moreover, if there is no direct relationship between the BILL and PATIENT tables, your trigger must determine the correct patient by traversing the existing relationships in the database.

-- Additionally, your trigger should account for scenarios where the operation does not meet the required business rules, such as when the referenced patient does not exist, 
--the billing amount is invalid (e.g., negative or NULL), or data integrity constraints are violated.

-- In the case of an error, the trigger must raise an exception with a clear and appropriate error message within the error-handling section. 
--Ensure that all potential failure scenarios such as inserting a billing record for a non-existent patient or providing invalid billing values are properly handled and tested.

SELECT * FROM INSURANCE_COMPANY;
SELECT * FROM DENTIST;
SELECT * FROM PATIENT;
SELECT * FROM APPOINTMENT;
SELECT * FROM TREATMENT;
SELECT * FROM VISIT;
SELECT * FROM BILL;
SELECT * FROM PAYMENT;
SELECT * FROM PAY;

GO
CREATE TRIGGER TRG_BILL_PATIENT_BALANCE
ON BILL
AFTER INSERT
AS
BEGIN
BEGIN TRY
IF EXISTS(SELECT * FROM INSERTED I JOIN VISIT V ON I.V_ID = V.V_ID JOIN APPOINTMENT A
				                                ON A.AP_ID = V.AP_ID JOIN PATIENT P 
				                                ON P.P_ID = A.P_ID WHERE I.B_TOTAL_AMOUNT IS NULL OR I.B_TOTAL_AMOUNT <= 0)
   BEGIN
   ROLLBACK TRANSACTION 
   RAISERROR('Bill amount cannot be null or negative or 0.', 16,1)
   END;
ELSE IF NOT EXISTS(SELECT P.P_ID FROM PATIENT P JOIN APPOINTMENT A
                                      ON P.P_ID = A.P_ID
									  JOIN VISIT V
									  ON A.AP_ID = V.AP_ID
									  JOIN INSERTED I 
									  ON I.V_ID = V.V_ID)
                              
   BEGIN
   ROLLBACK TRANSACTION
   RAISERROR('Patient does not exist.', 16,1)
   END;
ELSE 
   BEGIN
   UPDATE PATIENT 
   SET PAT_BALANCE = PAT_BALANCE + I.B_TOTAL_AMOUNT
   FROM PATIENT P JOIN APPOINTMENT A
                                      ON P.P_ID = A.P_ID
									  JOIN VISIT V
									  ON A.AP_ID = V.AP_ID
									  JOIN INSERTED I 
									  ON I.V_ID = V.V_ID
   END;

END TRY
BEGIN CATCH
  ROLLBACK TRANSACTION 
  RAISERROR('An error has occured.', 16,1);
END CATCH;

END;
GO

INSERT INTO APPOINTMENT
VALUES ('78901', '101', '1006', '2026-04-28', '8:00', 'Cleaning', 'SCHEDULED');
INSERT INTO VISIT
VALUES ('117', '2026-04-28', 'Very white.', '00011', '78901');
INSERT INTO BILL VALUES('207', '2026-04-28', 0, 'UNPAID', '117');

--INSERT INTO BILL VALUES('207', '2026-04-28', 155.00, 'UNPAID', '117');

delete from appointment
where ap_id = '78901'
delete from visit
where v_id = '117'
delete from bill
where b_id = '207'