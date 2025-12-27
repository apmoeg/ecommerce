<?php

$curl = curl_init();

curl_setopt_array($curl, [
  CURLOPT_URL => "http://app.bosta.co/api/v2/deliveries",
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_ENCODING => "",
  CURLOPT_FOLLOWLOCATION => true, // Follow redirects
  CURLOPT_MAXREDIRS => 10,
  CURLOPT_TIMEOUT => 30,
  CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
  CURLOPT_CUSTOMREQUEST => "POST",
  CURLOPT_POSTFIELDS => "{\n  \"type\": 10,\n  \"specs\": {\n    \"packageType\": \"Parcel\",\n    \"size\": \"MEDIUM\",\n    \"packageDetails\": {\n      \"itemsCount\": 2,\n      \"description\": \"Desc.\"\n    }\n  },\n  \"notes\": \"Welcome Note\",\n  \"cod\": 50,\n  \"dropOffAddress\": {\n    \"city\": \"Helwan\",\n    \"zoneId\": \"NQz5sDOeG\",\n    \"districtId\": \"aiJudRHeOt\",\n    \"firstLine\": \"Helwan street x\",\n    \"secondLine\": \"Near to Bosta school\",\n    \"buildingNumber\": \"123\",\n    \"floor\": \"4\",\n    \"apartment\": \"2\"\n  },\n  \"pickupAddress\": {\n    \"city\": \"Helwan\",\n    \"zoneId\": \"NQz5sDOeG\",\n    \"districtId\": \"aiJudRHeOt\",\n    \"firstLine\": \"Helwan street x\",\n    \"secondLine\": \"Near to Bosta school\",\n    \"buildingNumber\": \"123\",\n    \"floor\": \"4\",\n    \"apartment\": \"2\"\n  },\n  \"returnAddress\": {\n    \"city\": \"Helwan\",\n    \"zoneId\": \"NQz5sDOeG\",\n    \"districtId\": \"aiJudRHeOt\",\n    \"firstLine\": \"Maadi\",\n    \"secondLine\": \"Nasr  City\",\n    \"buildingNumber\": \"123\",\n    \"floor\": \"4\",\n    \"apartment\": \"2\"\n  },\n  \"businessReference\": \"43535252\",\n  \"receiver\": {\n    \"firstName\": \"Sasuke\",\n    \"lastName\": \"Uchiha\",\n    \"phone\": \"01065685435\",\n    \"email\": \"ahmed@ahmed.com\"\n  },\n  \"webhookUrl\": \"https://www.google.com/\"\n}",
  CURLOPT_HTTPHEADER => [
    "Authorization: 47a11c054cb5d9150c20fa16aee5caab6d3710c4616795974bd1be3551c6564a",
    "Content-Type: application/json"
  ],
]);

$response = curl_exec($curl);
$err = curl_error($curl);

curl_close($curl);

if ($err) {
  echo "cURL Error #:" . $err;
} else {
  echo $response;
}