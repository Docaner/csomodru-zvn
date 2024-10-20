stock UTIL_MenuButton(iNumber = -1) 
{
	new szButton[16];
	if(iNumber == -1) formatex(szButton, charsmax(szButton), "\r#.");
	else formatex(szButton, charsmax(szButton), "\y%d.", iNumber);
	
	return szButton;
}