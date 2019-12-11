# AirPasteboardOpen
Open source code for Air Pasteboard Mac OS app, which allows you to share pasteboard contents to Github Gist or upload a file via iCloud and Dropbox

![](demo.gif)

## How does it work?
- The app lives in the system bar on the top. You can click on the system bar icon to see options.
- Sharing pasteboard will use Github API. You need to supply a Github access token with Gist access in the app preferences. The Github token will be saved to MacOS Keychain.
- File sharing will try to fetch an iCloud drive link first. If that failed, a prompt will be shown to let you use Dropbox.
(Drag & Drop is also supported for file sharing) To share with Dropbox, you need to authenticate your Dropbox account. (If you are building the app yourself, you also need to configure the Dropbox API first)

## How to use

### Download from the App Store directly
You can download this app from the [Mac App Store page](https://apps.apple.com/us/app/air-pasteboard/id1327733671?mt=12). The App Store app has the same code as this repo, except for the added icon, the developer Dropbox token, and an option to modify Github API link in the preferences window.

### or, Build it
- Clone the code in the repo
- Add the third party frameworks in the `Cartfile`
- Obtain a Dropbox token and follow their [setup instructions](https://github.com/dropbox/SwiftyDropbox#configure-your-project).
(Some assets are not included in the open source repo due to image copyright requirements.)

#### Customize Github API link
If you are using Github Enterprise, you can modify the API request URL at [here](https://github.com/msztech/AirPasteboardOpen/blob/master/AirPasteBoard/GithubRequestHelper.swift#L17) in your local build.

## Contributions
Feel free to make a PR or create an issue

## Licsense

Please check the [LICENSE](LICENSE) file. The licsense file must be included in the visible part of all copies or modifications of this software code.

In addition, you cannot upload this code (or slightly modified code) to the App Store.
