# Passkit Sample Client

An experimental client to fetch, show and add a Pass to Apple Wallet.
This experiment is based on a Node.JS project not yet publicly available, which generates Passes following a model along with a webserver.
It can be virtually used for all the pass generators. 

This application asks for an URL to be inserted and a pass type to be selected from the main *UIPickerView*.
The request will be done on `<url>/gen/<selected-type>`.
Once retrieved the pass, it will let inspect its properties on another View Controller.

#### Structures

The client comes with two main structures to be respected: error and parameters sending, both managed as JSON Objects.

##### Error
This is the only important structure that must be returned from a web server in case of error, if you want to use this client.
```
{
	status: Bool,
    error: {
    	message: String
    }
}
```


#### Screenshots

![Screenshot](img/screen.png)
