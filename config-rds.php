<?php 
/**
 * Database Configuration with AWS RDS Support
 * 
 * This configuration supports both local development and AWS RDS deployment.
 * Uses environment variables when available (AWS EB, Docker, etc.)
 * Falls back to defaults for local development.
 */

// Detect environment
$isAWSEB = !empty(getenv('ELASTICBEANSTALK_ENVIRONMENT_NAME'));
$isDocker = !empty(getenv('DOCKER'));

// Database credentials - get from environment or use defaults
define('DB_HOST', getenv('RDS_DB_HOST') ?: getenv('DB_HOST') ?: 'localhost');
define('DB_USER', getenv('RDS_DB_USER') ?: getenv('DB_USER') ?: 'root');
define('DB_PASS', getenv('RDS_DB_PASSWORD') ?: getenv('DB_PASS') ?: '');
define('DB_NAME', getenv('RDS_DB_NAME') ?: getenv('DB_NAME') ?: 'library');

// Application settings
define('APP_DEBUG', filter_var(getenv('APP_DEBUG') ?: 'false', FILTER_VALIDATE_BOOLEAN));
define('LOG_LEVEL', getenv('LOG_LEVEL') ?: 'info');
define('APP_ENV', getenv('APP_ENV') ?: 'production');

// CloudWatch logging
define('ENABLE_CLOUDWATCH', filter_var(getenv('ENABLE_CLOUDWATCH') ?: 'true', FILTER_VALIDATE_BOOLEAN));

// Connection options
$pdoOptions = [
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'",
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

// SSL options for RDS
if ($isAWSEB) {
    $pdoOptions[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
}

// Establish database connection
try {
    $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME;
    $dbh = new PDO($dsn, DB_USER, DB_PASS, $pdoOptions);
    
    // Log successful connection
    error_log("Database connection established successfully");
    
} catch (PDOException $e) {
    // Log error to CloudWatch and file
    $errorMsg = "Database Connection Error: " . $e->getMessage();
    error_log($errorMsg);
    
    // In production, don't expose database details
    if (APP_ENV === 'production') {
        $displayMsg = "Unable to connect to database. Please contact administrator.";
    } else {
        $displayMsg = $errorMsg;
    }
    
    // Send SNS notification on critical errors
    if (function_exists('send_sns_notification')) {
        send_sns_notification("Database Connection Failed", $errorMsg);
    }
    
    exit("Error: " . $displayMsg);
}

/**
 * Helper function to send SNS notifications
 * 
 * @param string $subject Notification subject
 * @param string $message Notification message
 */
function send_sns_notification($subject, $message) {
    $snsTopicArn = getenv('SNS_TOPIC_ARN');
    if (!$snsTopicArn) {
        return; // SNS not configured
    }
    
    try {
        // Requires AWS SDK - uncomment if installed
        // require 'vendor/autoload.php';
        // $sns = new Aws\Sns\SnsClient(['region' => 'us-east-1']);
        // $sns->publish([
        //     'TopicArn' => $snsTopicArn,
        //     'Subject' => $subject,
        //     'Message' => $message
        // ]);
        
        // Fallback: Log to CloudWatch
        error_log("SNS Alert: $subject - $message");
    } catch (Exception $e) {
        error_log("Failed to send SNS notification: " . $e->getMessage());
    }
}
?>
