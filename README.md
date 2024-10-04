## RandomChain

**RandomChain** is a creative app where users can start and join themed chains, sharing photos and text with friends or random participants. Customize your profile, earn points through contributions, and explore finished chains. With features like a ranking system, notifications, and dark mode, RandomChain fosters creativity and connection in a fun social platform.

<img src="https://github.com/user-attachments/assets/12cded0c-c900-42c3-8105-5d37c0299773" alt="app_logo" width="200">

## Features

- **Chain Creation**: Users can initiate a new chain by setting parameters such as the number of contributors, privacy settings (friends-only or random), and a specific theme, allowing for personalized and engaging collaborative experiences.
- **Contribution Process**: Participants receive chains and can contribute by adding photos and text. They can view previous contributions and the theme before adding their own, creating a dynamic experience as the chain progresses. Also they can skip that pending chain if they want to.
- **Exploration of Finished Chains**: Users can browse through completed chains to see the creative contributions of others, offering inspiration and insight into different themes and collaboration styles and also can search chains by tags.
- **User Profiles**: Each user can create a profile that includes a profile picture (PFP), nickname, and country, allowing for personalization and helping others to identify and connect with them.
- **Ranking System**: A gamified ranking system rewards users with points based on their contributions. Different chain categories yield varying points, encouraging friendly competition and engagement within the community.
- **Social Features**: Users can like and save posts, fostering a sense of community. They can also report or block users to ensure a safe and positive environment for all participants.
- **Notifications**: Users receive notifications as quick as possible about new chains, contributions, and interactions, keeping them engaged and informed about their activity within the app. They can turn them off from settings.
- **Dark Mode**: An optional dark mode enhances user experience, making it easier on the eyes in low-light environments and allowing for a customizable app interface.
- **Multiple Login Options**: Users can sign in using various methods, including email and password, phone number, or Google Sign-In, providing flexibility and convenience.

## Implementation overview

- **Technologies used**: This app was made using **Flutter** for both frontend and backend.
- **Data Storage and Management**: User data, artwork information and other relevant data are stored in **Firebase**, a database hosted by Google.
- - **User authentication and authorization**: This is handled by **Firebase Authentication**. It requires each user to input an email and a strong password, or his phone number, in order to create an account, or he can use Google Sign In.
 
## Installation 

  In order to install ArtHub on your phone, you need to get all the files on your machine, that has **Android Studio** or **Visual Studio Code**, because using this tool, you can build the APK.

- **Step1**: Download all the files, either manually, or in your git bash use `git clone https://github.com/omuletzu/ArtHub`
- **Step2**: You have to open all this files as a project in **Android Studio** or **Visual Studio Code** and build the APK, and after this, using an USB cable get the APK on your phone and run the APK

## Usage

- **Sign in or create an account**: First of all you must login into your account or create one.
- **Explore**: In Explore category scroll through other's finished chains and see more details about them by pressing on them. You can also like, save, or report that chain
- **Pending chains / Unchained**: In this category, you will find all chains that wait for you to contribute. Also this is a place where you can start a new chain.
- **Friend / Explore people**: This is where you can either scroll through you friends, or random people and you can seach them using the search bar. Make new links by sending friend requests to other users, or if you want so you can block them.
- **Profile**: This category will give you information about your nickname, pfp, total points, and contributed chains. Based on your points you receive a rank from 1-9 and a specific more or less intensive color.
- **Other details**: From sliding menu, you are able to see you liked or saved chains, modify your personal data in *Edit Profile*, or set notifications and dark mode, on or off in *Settings*. In this sliding menu you also can sign out.

## Credits

- Flutter, Google Firebase, OneSignal
