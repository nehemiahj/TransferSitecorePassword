# TransferSitecorePassword
Ability to move all the password in a single button click

Transfer Password to new environment
Bringing the users and roles to the new environment will not bring the password. It may be necessary to manually reset user passwords after the transfer. Sitecore provided a simple utility to transfer the passwords to the destination server. [Sitecore KB](https://support.sitecore.com/kb?id=kb_article_view&sysparm_article=KB0242631)

You have to place the admin web page, provide the source and destination core or security db connection string. You will get an option to select the users to migrate their passwords. In the Sitecore provided file, you have to select one user at a time to move from left to right. 

I modified to add a button to transfer all the available user's passwords in a single click of a button (Transfer All). You can get this updated file. 

Note: In order for the tool to list the users, you need to make sure the users are already transferred to the destination Sitecore instance. 

[Blog](https://www.nehemiahj.com/2021/06/sitecore-upgrade-transfer-sitecore.html)
