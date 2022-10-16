USE HumanResources;

/* ------------------------------------------------------------------------- */
/* -------------------- RECRUITMENT ANALYSIS/CORRELATION ------------------- */
/* ------------------------------------------------------------------------- */

-- NOTE: DATASET UPLOADED WAS MODIFIED IN EXCEL SPLITTING THE EMPLOYEE NAME AND MANAGER NAME COLUMNS --
-- ADDING LAST NAME, FIRST NAME AND MIDDLE INITIAL COLUMNS FOR BOTH EMPLOYEES AND MANAGERS IN THE DATASET --  

-- CREATE COPY OF DATASET -- 

SELECT * INTO HRdatacopy 
FROM 
	(SELECT * FROM [HRDataset_v14(clean)]) AS HRdatacopy;

SELECT * FROM HRdatacopy;


-- CHECK FOR DUPLICATES ROWS IN HRdatacopy DATA -- 

WITH duplicates AS (
		SELECT Employee_Name, EmpID, Salary, DOB, ManagerID, 
		ROW_NUMBER() OVER(PARTITION BY Employee_Name, EmpID, Salary, DOB, ManagerID 
		ORDER BY Employee_Name, EmpID, Salary, DOB, ManagerID) AS ROW_NUM
		FROM HRdatacopy)
SELECT * FROM duplicates WHERE ROW_NUM > 1;

-- NO DUPLICATE ROWS FOUND IN DATASET -- 



/* BASIC DEMOGRAPHICS */

-- NUMBER OF FEMALES/MALES -- 

SELECT Sex, COUNT(Sex) AS 'Count'
FROM HRdatacopy
GROUP BY Sex; 

-- DISTRIBUTION OF RACE DESCRIPTION (WHILE ALSO ACCOUNTING FOR HISPANIC/LATINO DISTINCTION) -- 

SELECT RaceDesc, COUNT(RaceDesc) AS 'Count', 
COUNT(CASE 
	WHEN HispanicLatino = 'Yes' THEN 1
	ELSE NULL
END) AS 'Hispanic/Latino'
FROM HRdatacopy
GROUP BY RaceDesc
ORDER BY 'Count' DESC;

-- AGE DISTRIBUTION -- 

WITH age AS (
		SELECT DATEDIFF(YEAR, DOB, CONVERT(VARCHAR, GETDATE(), 1)) AS 'Age'
		FROM HRdatacopy)
SELECT *, COUNT(Age) AS 'Count'
FROM age
GROUP BY age;

-- CITIZENSHIP -- 

SELECT CitizenDesc, COUNT(CitizenDesc) AS 'Count'
FROM HRdatacopy
GROUP BY CitizenDesc
ORDER BY 'Count' DESC;


/* BASIC HR INFORMATION/DISTRIBUTION */

-- DISTRIBUTION OF EMPLOYEES IN DATASET (ACTIVE/NON-ACTIVE) --

SELECT 
COUNT(CASE 
		WHEN EmploymentStatus = 'Active' THEN 1
		ELSE NULL
	END) AS 'Active',
COUNT(CASE
		WHEN EmploymentStatus = 'Terminated for Cause' OR 
		EmploymentStatus = 'Voluntarily Terminated' THEN 1
		ELSE NULL
	END) AS 'Non-active'
FROM HRdatacopy;

-- NUMBER OF DEPARTMENTS -- 

SELECT COUNT(DISTINCT Department) AS 'Number of Departments'
FROM HRdatacopy

-- LIST DEPARTMENT NAMES -- 

SELECT DISTINCT DEPARTMENT AS 'Departments'
FROM HRdatacopy;

-- NUMBER OF SPECIAL PROJECTS BY DEPARTMENT -- 
SELECT Department, SUM(SpecialProjectsCount) AS '# of Special Projects' 
FROM HRdatacopy
GROUP BY Department;

-- NUMBER OF EMPLOYEES IN EACH DEPARTMENT (INCLUDING SEX DISTRIBUTION) -- 

SELECT Department, COUNT(EmpID) AS 'Number of Employees', 
COUNT(CASE
		WHEN Sex = 'F' THEN 1 ELSE NULL
	END) AS 'Female',
COUNT(CASE
		WHEN Sex = 'M' THEN 1 ELSE NULL
	END) AS 'Male'
FROM HRdatacopy
GROUP BY Department
ORDER BY 'Number of Employees' DESC;

-- DISTRIBUTION OF RACE DESCRIPTION IN EACH DEPARTMENT (ACTIVE EMPLOYEES) --

SELECT Department, COUNT(EmpID) AS 'Number of Employees', 
COUNT(CASE
		WHEN RaceDesc = 'American Indian or Alaska Native' THEN 1 ELSE NULL
	END) AS 'American Indian or Alaska Native',
COUNT(CASE
		WHEN RaceDesc = 'Asian' THEN 1 ELSE NULL
	END) AS 'Asian',
COUNT(CASE
		WHEN RaceDesc = 'Black or African American' THEN 1 ELSE NULL
	END) AS 'Black or African American',
COUNT(CASE
		WHEN RaceDesc = 'Hispanic' THEN 1 ELSE NULL
	END) AS 'Hispanic',
COUNT(CASE
		WHEN RaceDesc = 'Two or more races' THEN 1 ELSE NULL
	END) AS 'Two or more races',
COUNT(CASE
		WHEN RaceDesc = 'White' THEN 1 ELSE NULL
	END) AS 'White'
FROM HRdatacopy
WHERE EmploymentStatus = 'Active'
GROUP BY Department
ORDER BY 'Number of Employees' DESC;

-- AVERAGE SALARIES IN EACH DEPARTMENT -- 

SELECT Department, CAST(AVG(Salary) AS INT) AS 'Avg. Salary'
FROM HRdatacopy
GROUP BY Department
ORDER BY 'Avg. Salary' DESC;

-- AVERAGE SALARIES IN EACH DEPARTMENT (ACCOUNTING FOR SEX) -- 

WITH m_salaries AS
	(SELECT Department, CAST(AVG(Salary) AS INT) AS 'Avg. Male Salary'
	FROM HRdatacopy
	WHERE Sex = 'M'
	GROUP BY Department),
	f_salaries AS
	(SELECT Department, CAST(AVG(Salary) AS INT) AS 'Avg. Female Salary'
	FROM HRdatacopy
	WHERE Sex = 'F'
	GROUP BY Department)
SELECT f_salaries.Department,
ISNULL(m_salaries.[Avg. Male Salary],0) AS 'Avg. Male Salary',
ISNULL(f_salaries.[Avg. Female Salary],0) AS 'Avg. Female Salary',
ISNULL(([Avg. Male Salary] - [Avg. Female Salary]),0) AS 'Salary Difference'
FROM m_salaries
RIGHT OUTER JOIN f_salaries
ON m_salaries.Department = f_salaries.Department;

-- AVG. SALARIES OF POSITIONS EACH YEAR -- 

SELECT YEAR(DateofHire) AS 'Year', Position, ROUND(AVG(Salary),0) AS 'Avg. Salary'
FROM HRdatacopy
GROUP BY YEAR(DateofHire), Position
ORDER BY 'Year';


-- DISPLAY CHANGES IN AVG. SALARIES FOR EACH POSITION OVER TIME -- 

SELECT * 
FROM 
	(SELECT Position, YEAR(DateofHire) AS 'Year', CAST(Salary AS INT) AS 'Salary' FROM HRdatacopy) AS p
PIVOT
(
	AVG(p.Salary)
	FOR [Year] IN ([2006], [2007], [2008], [2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018]))
AS pivot_table



----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------


/* BASIC RECRUITMENT INFORMATION */ 

-- LIST OF RECRUITMENT SOURCES -- 

SELECT DISTINCT RecruitmentSource
FROM HRdatacopy;

-- NUMBER OF EMPLOYEES HIRED FROM 2006-2018 FROM EACH RECRUITMENT SOURCE WITH TOTALS -- 

SELECT YEAR(DateofHire) AS 'Year', COALESCE(RecruitmentSource, 'Total') AS 'Recruitment Source', COUNT(RecruitmentSource) AS 'Count'
FROM HRdatacopy
GROUP BY ROLLUP(YEAR(DateofHire), RecruitmentSource);

-- NUMBER OF EMPLOYEES RECEIVED FROM EACH RECRUITMENT SOURCE (ACCOUNTING FOR SEX DISTRIBUTION) -- 

SELECT RecruitmentSource, COUNT(EmpID) AS 'Employees Recruited', 
COUNT(CASE
		WHEN Sex = 'F' THEN 1 ELSE NULL
	END) AS 'Female',
COUNT(CASE
		WHEN Sex = 'M' THEN 1 ELSE NULL
	END) AS 'Male'
FROM HRdatacopy
GROUP BY RecruitmentSource;

-- NUMBER OF EMPLOYEES RECEIVED FROM EACH RECRUITMENT SOURCE (ACCOUNTING FOR RACE DESCRIPTION) -- 

SELECT RecruitmentSource, COUNT(EmpID) AS 'Employees Recruited', 
COUNT(CASE
		WHEN RaceDesc = 'American Indian or Alaska Native' THEN 1 ELSE NULL
	END) AS 'American Indian or Alaska Native',
COUNT(CASE
		WHEN RaceDesc = 'Asian' THEN 1 ELSE NULL
	END) AS 'Asian',
COUNT(CASE
		WHEN RaceDesc = 'Black or African American' THEN 1 ELSE NULL
	END) AS 'Black or African American',
COUNT(CASE
		WHEN RaceDesc = 'Hispanic' THEN 1 ELSE NULL
	END) AS 'Hispanic',
COUNT(CASE
		WHEN RaceDesc = 'Two or more races' THEN 1 ELSE NULL
	END) AS 'Two or more races',
COUNT(CASE
		WHEN RaceDesc = 'White' THEN 1 ELSE NULL
	END) AS 'White'
FROM HRdatacopy
GROUP BY RecruitmentSource;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- FINDING THE NUMBER OF EMPLOYEES HIRED AND LOST EACH YEAR BY DEPARTMENT -- 


WITH hired_employees AS
		(SELECT YEAR(DateofHire) AS 'Year', COALESCE(Department, 'Totals') AS 'Department',
				COUNT(YEAR(DateofHire)) AS 'Employees Hired'
				FROM HRdatacopy
				GROUP BY YEAR(DateofHire), Department),
	lost_employees AS
		(SELECT YEAR(DateofTermination) AS 'Year', COALESCE(Department, 'Totals') AS 'Department',
				COUNT(YEAR(DateofTermination)) AS 'Employees Lost'
				FROM HRdatacopy
				GROUP BY YEAR(DateofTermination), Department)
SELECT hired_employees.[Year], hired_employees.Department,
ISNULL(hired_employees.[Employees Hired],0) AS 'Employees Hired', ISNULL(lost_employees.[Employees Lost],0) AS 'Employees Lost'
FROM hired_employees
LEFT OUTER JOIN lost_employees
ON hired_employees.[Year] = lost_employees.[Year] AND hired_employees.[Department] = lost_employees.[Department]
ORDER BY [Year], Department;


-- NUMBER OF EMPLOYEES HIRED FOR EACH POSITION EACH YEAR -- 
SELECT * 
FROM 
	(SELECT Position, YEAR(DateofHire) AS 'Year', EmpID AS 'Number of Employees' FROM HRdatacopy) AS e
PIVOT
(
	COUNT(e.[Number of Employees])
	FOR [Year] IN ([2006], [2007], [2008], [2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018]))
AS pivot_table

-- NUMBER OF EMPLOYEES LOST FOR EACH POSITION EACH YEAR -- 
SELECT * 
FROM 
	(SELECT Position, YEAR(DateofTermination) AS 'Year', EmpID AS 'Number of Employees' FROM HRdatacopy) AS e
PIVOT
(
	COUNT(e.[Number of Employees])
	FOR [Year] IN ([2006], [2007], [2008], [2009], [2010], [2011], [2012], [2013], [2014], [2015], [2016], [2017], [2018]))
AS pivot_table



-- CALCULATING COMPANY TENURES FOR INACTIVE EMPLOYEES (ONLY THOSE WHO LEFT THE COMPANY FOR RETENTION PURPOSES)--
-- ACCOUNTING FOR RACE DESCRIPTION DISTRIBUTION -- 

SELECT DATEDIFF(YEAR, DateofHire, DateofTermination) AS 'Years of Service',
COUNT(DATEDIFF(YEAR, DateofHire, DateofTermination)) AS 'Number of Employees',
COUNT(CASE
		WHEN RaceDesc = 'American Indian or Alaska Native' THEN 1 ELSE NULL
	END) AS 'American Indian or Alaska Native',
COUNT(CASE
		WHEN RaceDesc = 'Asian' THEN 1 ELSE NULL
	END) AS 'Asian',
COUNT(CASE
		WHEN RaceDesc = 'Black or African American' THEN 1 ELSE NULL
	END) AS 'Black or African American',
COUNT(CASE
		WHEN RaceDesc = 'Hispanic' THEN 1 ELSE NULL
	END) AS 'Hispanic',
COUNT(CASE
		WHEN RaceDesc = 'Two or more races' THEN 1 ELSE NULL
	END) AS 'Two or more races',
COUNT(CASE
		WHEN RaceDesc = 'White' THEN 1 ELSE NULL
		END) AS 'White'
FROM HRdatacopy
WHERE EmploymentStatus = 'Voluntarily Terminated'
GROUP BY DATEDIFF(YEAR, DateofHire, DateofTermination);


-- CALCULATING COMPANY TENURES FOR INACTIVE EMPLOYEES (ONLY THOSE WHO LEFT THE COMPANY FOR RETENTION PURPOSES)--
-- ACCOUNTING FOR SEX DISTRIBUTION -- 

SELECT DATEDIFF(YEAR, DateofHire, DateofTermination) AS 'Years of Service',
COUNT(DATEDIFF(YEAR, DateofHire, DateofTermination)) AS 'Number of Employees',
COUNT(CASE
		WHEN Sex = 'F' THEN 1 ELSE NULL
	END) AS 'Female',
COUNT(CASE
		WHEN Sex = 'M' THEN 1 ELSE NULL
	END) AS 'Male'
FROM HRdatacopy
WHERE EmploymentStatus = 'Voluntarily Terminated'
GROUP BY DATEDIFF(YEAR, DateofHire, DateofTermination);
		

-- DEPARTURE REASONS FOR EMPLOYEES THAT VOLUNTARILY CHOSE TO LEAVE -- 

SELECT TermReason, COUNT(TermReason) AS 'Count'
FROM HRdatacopy
WHERE EmploymentStatus = 'Voluntarily Terminated'
GROUP BY TermReason
ORDER BY 'Count' DESC;

-- DEPARTURE REASONS FOR EMPLOYEES THAT VOLUNTARILY CHOSE TO LEAVE (SEGMENTED BY SEX) -- 

WITH women_TermReason AS(
			SELECT TermReason, COUNT(TermReason) AS 'Count'
			FROM HRdatacopy
			WHERE EmploymentStatus = 'Voluntarily Terminated' AND Sex = 'F'
			GROUP BY TermReason),
	men_TermReason AS(
			SELECT TermReason, COUNT(TermReason) AS 'Count'
			FROM HRdatacopy
			WHERE EmploymentStatus = 'Voluntarily Terminated' AND Sex = 'M'
			GROUP BY TermReason)
SELECT m.TermReason AS 'Reasons for Voluntary Departure', ISNULL(w.[Count],0) AS 'Women', ISNULL(m.[Count],0) AS 'Men',
(ISNULL(w.[Count],0) + ISNULL(m.[Count],0)) AS 'Total'
FROM women_TermReason AS w
RIGHT OUTER JOIN men_TermReason AS m
ON w.TermReason = m.TermReason
GROUP BY m.TermReason, w.[Count], m.[Count]
ORDER BY m.TermReason;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- FINDING THE DEPARTMENTS WHERE THE TOP 3 REASONS FOR LEAVING OCCUR --

SELECT Department, TermReason, COUNT(TermReason) AS 'Count'
FROM HRdatacopy
WHERE TermReason IN ('Another position', 'unhappy', 'more money')
GROUP BY Department, TermReason
ORDER BY 'Count' DESC;

-- THE PRODUCTION DEPARTMENT APPEARS TO LOSE THE MOST EMPLOYEES DUE TO THESE REASONS -- 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- AVERAGE ENGAGEMENT, SATISFACTION AND PERFORMANCE SCORES (SEGMENTED BY SEX) --

SELECT Sex, ROUND(AVG(EngagementSurvey),2) AS 'avg_engagement', ROUND(AVG(EmpSatisfaction), 2) AS 'avg_satisfaction', ROUND(AVG(PerfScoreID),2) AS 'avg_performance'
FROM HRdatacopy
GROUP BY Sex;

-- AVERAGE ENGAGEMENT, SATISFACTION AND PERFORMANCE SCORES BY DEPARTMENT -- 

SELECT Department, ROUND(AVG(EngagementSurvey),2) AS 'avg_engagement', ROUND(AVG(EmpSatisfaction),2) AS 'avg_satisfaction', ROUND(AVG(PerfScoreID),2) AS 'avg_performance'
FROM HRdatacopy
GROUP BY Department



----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------


/* CORRELATION */

/* 1ST CORRELATION SET - ATTEMPT TO DETERMINE IF THERE IS A CORRELATION BETWEEN EMPLOYEE SATISFACTION AND ENGAGEMENT SURVEY */

-- CORRELATION BETWEEN EMPLOYEE SATISFACTION AND ENGAGEMENT SURVEY SCORE -- 

SELECT ((AVG(EngagementSurvey * EmpSatisfaction)) - (AVG(EngagementSurvey) * AVG(EmpSatisfaction)))/
((STDEVP(EngagementSurvey) * (STDEVP(EmpSatisfaction)))) AS 'pearson_coeffiecient'
FROM HRdatacopy;

/* 2ND CORRELATION SET - ATTEMPT TO DETERMINE IF THERE IS A CORRELATION BETWEEN EMPLOYEE SATISFACTION AND PERFORMANCE SCORE */

-- CORRELATION BETWEEN PERFORMANCE SCORE AND EMPLOYEE SATISFACTION -- 

SELECT ((AVG(PerfScoreID * EmpSatisfaction)) - (AVG(PerfScoreID) * AVG(EmpSatisfaction)))/
((STDEVP(PerfScoreID) *(STDEVP(EmpSatisfaction)))) AS 'pearson_coefficient'
FROM HRdatacopy;

/* 3RD CORRELATION SET - ATTEMPT TO DETERMINE IF THERE IS A CORRELATION BETWEEN PERFORMANCE SCORE AND ENGAGEMENT SURVEY */

-- CORRELATION BETWEEN PERFORMANCE SCORE AND ENGAGEMENT SURVEY SCORE -- 

SELECT ((AVG(PerfScoreID * EngagementSurvey)) - (AVG(PerfScoreID) * AVG(EngagementSurvey)))/
((STDEVP(PerfScoreID) *(STDEVP(EngagementSurvey)))) AS 'pearson_coefficient'
FROM HRdatacopy;












----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------



