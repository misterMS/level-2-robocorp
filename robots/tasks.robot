*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${DOWNLOAD_DIRECTORY}=      ${OUTPUT_DIR}${/}temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${website_url}=    Get website URL from vault
    ${robot_order_url}=    Collect URL from user
    Download the csv file    ${robot_order_url}
    ${orders_csv}=    Read the csv file
    Create download directory
    Open the robot order website    ${website_url}
    FOR    ${row}    IN    @{orders_csv}
        Close the annoying modal
        Fill the form    ${row}
        Create pdf of receipt    ${row}
        Embed screenshot to pdf    ${row}
        Click another order
    END
    Create a zip file
    [Teardown]    Close the robot order website and delete temp folder


*** Keywords ***
Get website URL from vault
    ${url}=    Get Secret    credentials
    RETURN    ${url}[url]

Collect URL from user
    Add heading    Mention URL for CSV file
    Add text input    URL
    ${response}=    Run dialog
    RETURN    ${response}[URL]

Download the csv file
    [Arguments]    ${robot_order_url}
    Download    ${robot_order_url}    overwrite=True

Read the csv file
    ${orders_csv}=    Read table from CSV    orders.csv    dialect=excel
    RETURN    ${orders_csv}

Create download directory
    Create Directory    ${DOWNLOAD_DIRECTORY}

Open the robot order website
    [Arguments]    ${website_url}
    Open Available Browser    ${website_url}

Close the annoying modal
    Wait Until Page Contains Element    css:button.btn.btn-dark    timeout=60
    Click Button    css:button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    Wait Until Page Contains Element    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    10x    1 sec    Click order

Click order
    Click Button    id:order
    Wait Until Page Contains Element    id:receipt    timeout=2

Create pdf of receipt
    [Arguments]    ${row}
    ${order_pdf}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_pdf}    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].pdf

Embed screenshot to pdf
    [Arguments]    ${row}
    Screenshot    id:robot-preview-image    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].png
    Open Pdf    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].pdf
    ${screenshot_path}=    Create List
    ...    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].pdf
    ...    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].png
    Add Files To Pdf    ${screenshot_path}    ${DOWNLOAD_DIRECTORY}${/}${row}[Order number].pdf
    Close Pdf

Click another order
    Click Button    id:order-another

Close the robot order website and delete temp folder
    Close Browser
    Remove Directory    ${DOWNLOAD_DIRECTORY}    True

Create a zip file
    Archive Folder With Zip    ${DOWNLOAD_DIRECTORY}    ${OUTPUT_DIR}${/}PDFs.zip
