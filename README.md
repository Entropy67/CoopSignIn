# CoopSignIn

## Introduction
I developed an App for chore shift management. Members can check-in/-out through the APP.
Besides, the APP keeps track of the time points and generate no-show or credit report 
accordingly. It also allows crew managers to manage the schedule by adding/editing/deleting a shift.

## Usage
The APP is now available in TestFlight. Feel free to contact me if you want access. It will be published in APP store soon. 

It has two modes: offline mode and Google drive mode

### Off-line mode
Everything will be conducted locally within the app. You can register a permanent or one-time shift in the APP. The data will be stored in the local device.

### Google-drive mode
Once sign-in with a Google account, it will work with APIs from Google drive. First, it can locate and download sign-in sheet from the Google drive linked to your account. Second, it will upload the data to  Google drive so that you can review the reports remotely. 

## Modules

### viewController.swift
The viewController class presents the complete sign-in sheet, 
defines all kinds of managers and trigger all kinds of views. 
Everything starts from here.

### Controllers
Controller folder contains different ViewControllers which control the APP View. 
- SignInViewController: a view to allow members to sign-in/out
- AddChoreViewController:  controls a View to allow user to add a permenant chore shift
- AddCrewViewController: controls a View to  allow user to add/edit/delete a crew
- AddViewController: controls a View to register a one-time (not permenant) credit/temp/regular shift
- FileViewController: presents a tableview of reports (csv spreadsheet and logs)
- InfoViewController: presents a table with all timestamp information
- LogViewController: shows all the log
- EditManagerViewController: an prototype class to edit manager information
- MemberInfoViewController: a pop-up view to present memmber information
- SettingViewController: presents a view to allow user to change the setting.



Those controllers will directly interact with managers to achieve functions in needs.

### Managers
Managers manage different models according to the request from users through controllers.
- Manager: a prototype class for different managers
- AlertManager: sending alert
- ChoreManager: manage permenant chore shift 
- CrewManager: add/edit/delete crews
- DataManager: save/update data
- DateManager: useful functions to manipulate date variables
- GoogleDriveManager: connect with Google drive
- LogManager: write info to log
- MemberManager: manage member information
- OptionManager: controls the option menu
- PolictyManager: records different policies
- SecurityManager: auto-lock the advanced options, unlock the advanced options.
- ShiftManager: manage all the shifts in a day

### Models
Models are basic elements of the system.
- Chore: permenant weekly chore shift
- Crew: groups of chore
- Person: with name and id
- Setting: setting element
- Shifts: a particular chore shift
- Status: records status of a Shift



