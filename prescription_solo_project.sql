-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims. Dr. Bruce Pendley
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;
-- MD
SELECT *
FROM prescriber
WHERE npi ='1881634483'

-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT p.npi, 
       p.nppes_provider_first_name, 
       p.nppes_provider_last_org_name, 
       p.specialty_description, 
       SUM(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr USING (npi)
WHERE p.npi = '1881634483'
GROUP BY p.npi, p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description;

-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT p.specialty_description, 
       SUM(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr USING (npi)
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

-- 2b.Which specialty had the most total number of claims for opioids?
SELECT p.specialty_description, 
	SUM(pr.total_claim_count) AS total_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi 
JOIN drug d ON pr.drug_name = d.drug_name 
WHERE d.opioid_drug_flag = 'Y'  
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 1;

SELECT *
FROM drug

-- 2c.Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
-- SELECT DISTINCT p.specialty_description
-- FROM prescriber p
-- LEFT JOIN prescription pr ON p.npi = pr.npi
-- WHERE pr.npi IS NULL; incorrect 

(select specialty_description, count(drug_name) as presciption_count
from prescriber
left join prescription
	using (npi)
group by specialty_description)
except
(select specialty_description, count(drug_name)
from prescriber
left join prescription
	using (npi)
where drug_name is not null
group by specialty_description);

-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT p.specialty_description,
 	   ROUND(100.0 * SUM(CASE WHEN d.opioid_drug_flag = 'Y' 
    THEN pr.total_claim_count 
    ELSE 0 END) 
/   SUM(pr.total_claim_count), 2) AS opioid_percentage
FROM prescriber p
JOIN prescription pr USING (npi)
JOIN drug d ON pr.drug_name = d.drug_name
GROUP BY p.specialty_description
ORDER BY opioid_percentage DESC;

-- 3a. Which drug (generic_name) had the highest total drug cost?
SELECT d.generic_name, 
       SUM(p.total_drug_cost) AS total_cost
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY total_cost DESC
LIMIT 1;

-- 3b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT d.generic_name, 
       ROUND(SUM(p.total_drug_cost) / SUM(p.total_day_supply), 2) AS cost_per_day
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
GROUP BY d.generic_name
ORDER BY cost_per_day DESC
LIMIT 1;

-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this.
SELECT drug_name,
       CASE 
           WHEN opioid_drug_flag = 'Y' THEN 'opioid'
           WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
           ELSE 'neither' 
       END AS drug_type
from drug;

-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
    END AS drug_type, 
    SUM(p.total_drug_cost)::MONEY AS total_spent
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y' OR d.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_spent DESC;

-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
select state, count(cbsa)
from cbsa
join fips_county
	using (fipscounty)
where state = 'TN'
group by state;

-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT c.cbsaname, SUM(p.population) AS total_population
FROM cbsa c
JOIN population p ON c.fipscounty = p.fipscounty  
GROUP BY c.cbsaname
ORDER BY total_population DESC
LIMIT 1;

SELECT c.cbsaname, SUM(p.population) AS total_population
FROM cbsa c
JOIN population p ON c.fipscounty = p.fipscounty  
GROUP BY c.cbsaname
ORDER BY total_population ASC
LIMIT 1;

-- 5c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
with non_cbsa_counties as (
	select fipscounty
	from population
	except
	select fipscounty
	from cbsa)
select county, population
from fips_county
join population
	using (fipscounty)
join non_cbsa_counties
	using (fipscounty)
order by population desc;

-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT *
FROM prescription;

SELECT total_claim_count, drug_name
FROM prescription
WHERE total_claim_count >=3000
GROUP BY total_claim_count, drug_name 
ORDER BY total_claim_count DESC;

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT pr.total_claim_count, 
       pr.drug_name, 
       CASE 
           WHEN d.opioid_drug_flag = 'Y' THEN 'Opioid'
           ELSE 'Non-Opioid' 
       END AS opioid_status
FROM prescription pr
JOIN drug d ON pr.drug_name = d.drug_name
WHERE pr.total_claim_count >= 3000
GROUP BY pr.total_claim_count, pr.drug_name, d.opioid_drug_flag
ORDER BY pr.total_claim_count DESC;


-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
    p.total_claim_count, 
    p.drug_name, 
    pr.npi, 
    pr.nppes_provider_first_name, 
    pr.nppes_provider_last_org_name
FROM prescription p
JOIN prescriber pr ON pr.npi = p.npi
WHERE p.total_claim_count >= 3000
GROUP BY p.total_claim_count, p.drug_name, pr.npi, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
ORDER BY p.total_claim_count DESC;

-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT pr.npi, d.drug_name
FROM prescriber pr
CROSS JOIN drug d
WHERE pr.specialty_description = 'Pain Management'
AND pr.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y';

-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
select npi, drug.drug_name, COALESCE(sum(total_claim_count)) as total_claims
from prescriber
cross join drug
join prescription
	using (npi)
where specialty_description = 'Pain Management'
	and nppes_provider_city = 'NASHVILLE'
	and opioid_drug_flag = 'Y'
group by npi, drug.drug_name;