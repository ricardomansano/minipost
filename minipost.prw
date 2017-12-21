#include "totvs.ch"
/*/	-----------------------------------------------------------------/
Exemplo para o segundo video sobre o CloudBridge
/-------------------------------------------------------------------*/
function u_miniPost()
local tempPath := GetTempPath()
local i, oDlg, cFile, nHandle, globalLink
local cOS := getOS()
local aFiles := {"bootstrap.min.css",;
					 "jquery-1.10.2.min.js",;
					 "totvstec.js",;
					 "minipost.html",;
					 "minipost.css",;
					 "img_avatar1.png",;
					 "img_avatar2.png",;
					 "img_avatar3.png",;
					 "img_avatar4.png",;
					 "img_avatar5.png",;
					 "img_avatar6.png"}
private oMiniPost, oMobile
private isMobile := .F.

oDlg := TWindow():New(10, 10, 800, 600, "TOTVS - Exemplo video CloudBridge #2")
    // --------------------------------------------------------------------------------
    // Nos dispositivos moveis os arquivos HTML5 sao copiados para pasta ASSETS 
    // durante a compilacao do projeto e nao precisam ser baixados do RPO 
    // --------------------------------------------------------------------------------
    if cOS == "ANDROID" .or. cOS == "IPHONEOS"

    	// --------------------------------------------------------------------------------
    	// O componente TMobile eh o reponsavel por acessar o dispositivo
    	// Mais informacoes em: http://tdn.totvs.com/display/tec/TMobile
    	// --------------------------------------------------------------------------------
    	oMobile := TMobile():New()
    	oMobile:SetScreenOrientation(-1)

    	isMobile := .T.
    	if cOS == "ANDROID"
    		tempPath := "file:///android_asset/web/"
    	else
    		tempPath := GetPvProfString("ENVIRONMENT", "ASSETSPATH", "Erro", GetSrvIniName()) + "/web/"
    	endif
    else
    	// --------------------------------------------------------------------------------
	    // Baixa arquivos do RPO no TEMP
	    // --------------------------------------------------------------------------------
		for i := 1 to len(aFiles)
			cFile :=  + aFiles[i]
			cFileContent := getApoRes(cFile)

			if cFileContent == Nil
				msgAlert("Arquivo " + cFile + " nao existe no RPO, favor compilar o arquivo")
				return
			else
				nHandle := fCreate(tempPath+cFile)
				fWrite(nHandle, cFileContent)
				fClose(nHandle)
			endif
		next i
	endif
       
   	// --------------------------------------------------------------------------------
    // TWebChannel eh responsavel pelo trafego entre o SmartClient e o JavaScript
   	// --------------------------------------------------------------------------------
    oWebChannel := TWebChannel():New()
    oWebChannel:connect()
    if !oWebChannel:lConnected
    	msgStop("Erro na conexao com o WebSocket")
    	return
    endif
    
   	// --------------------------------------------------------------------------------
    // IMPORTANTE: Aqui definimos a porta WebSocket que sera utilizada para comunicacao 
    // --------------------------------------------------------------------------------
    globalLink := tempPath + "minipost.html?port=" + cValToChar(oWebChannel:nPort)

   	// --------------------------------------------------------------------------------
    // O comando JavaScript dialog.jsToAdvpl()sera tratado por este bloco de codigo
   	// --------------------------------------------------------------------------------
	oWebChannel:bJsToAdvpl := {|self,codeType,codeContent| jsToAdvpl(self,codeType,codeContent) } 
	
   	// --------------------------------------------------------------------------------
	// Componente do navegador embutido
   	// --------------------------------------------------------------------------------
	oMiniPost := miniPost():New(oDlg,0,0,0,0)
	oMiniPost:oWebEngine:navigate(globalLink)
    oMiniPost:oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
    
oDlg:Activate("MAXIMIZED")
Return

/*/	-----------------------------------------------------------------/
Captura imagem
/-------------------------------------------------------------------*/
static function takePicture()
	if !isMobile
		jsAlert("TakePicture", "TakePicture sera executado apenas nos dispositivos")
		return
	endif
	
   	// --------------------------------------------------------------------------------
	// Exibe imagem capturada
   	// --------------------------------------------------------------------------------
	cFile := oMobile:TakePicture(0)
	conout("", "TakePicrure", cFile)
	
	if !empty(cFile)
		beginContent var cImage
	        <div id="takePicture">
	            <button class="close" onclick="removeImage(this);">
	                <span aria-hidden="true"><font size=12>&times;</font></span></button>
	            <img src="%Exp:cFile%" width="90%">
	        </div>
		endContent
		oWebChannel:advplToJs("showImage", cImage)
	endif
return

/*/	-----------------------------------------------------------------/
Retorna Geolocalizacao
/-------------------------------------------------------------------*/
static function getGeoCoordinate()
	if !isMobile
		jsAlert("GetGeoCoordinate", "GetGeoCoordinate sera executado apenas nos dispositivos")
		return
	endif

   	// --------------------------------------------------------------------------------
   	// Exibe geolocalizacao
   	// --------------------------------------------------------------------------------
	cLocation := oMobile:GetGeoCoordinate(0)
	jsAlert("Geolocalizacao", cLocation)
	conout("", "Geolocalizacao", cLocation)
return

/*/	-----------------------------------------------------------------/
Retorna o Sistema Operacional em uso
/-------------------------------------------------------------------*/
static function getOS()
local stringOS := Upper(GetRmtInfo()[2])

	if ("ANDROID" $ stringOS)
    	return "ANDROID" 
	elseif ("IPHONEOS" $ stringOS)
		return "IPHONEOS"
	elseif GetRemoteType() == 0 .or. GetRemoteType() == 1
		return "WINDOWS"
	elseif GetRemoteType() == 2 
		return "UNIX" // Linux ou MacOS		
	elseif GetRemoteType() == 5 
		return "HTML" // Smartclient HTML		
	endif
	
return ""

/*/	-----------------------------------------------------------------/
Bloco de codigo que recebera as chamadas JavaScript
/-------------------------------------------------------------------*/
static function jsToAdvpl(self,codeType,codeContent)
	// Exibe mensagens trocadas
	conout("",;
		   "jsToAdvpl->codeType: " + codeType,;
		   "jsToAdvpl->codeContent: " + codeContent)
			
	do case
		// ------------------------------------------
		// Termino da carga da pagina HTML
		// ------------------------------------------
		case codeType == "pageStarted"
			loadPage()

		// ------------------------------------------
		// Decrementa contador quando o post foi deletado via JavaScript
		// ------------------------------------------
		case codeType == "deletePost"
			oMiniPost:nCount--

		// ------------------------------------------
		// Insere posts
		// ------------------------------------------
		case codeType == "inserePosts"
			oMiniPost:insere()
		
		// ------------------------------------------
		// Deleta primeiro post da lista
		// ------------------------------------------
		case codeType == "deleteFirst"
			oMiniPost:deletaFirst()
		
		// ------------------------------------------
		// Exibe quantidade de posts visiveis
		// ------------------------------------------
		case codeType =="countPosts"
			jsAlert("Count()", cValTochar(oMiniPost:count())+" posts incluidos") 
			
		// ------------------------------------------
		// Captura imagem
		// ------------------------------------------
		case codeType == "takePicture"
			takePicture()
		
		// ------------------------------------------
		// Retorna geolocalizacao
		// ------------------------------------------
		case codeType == "getGeoCoordinate"
			getGeoCoordinate()
		
		// ------------------------------------------
		// Fecha aplicacao
		// ------------------------------------------
		case codeType == "closeApp"
			__Quit()
	endCase
	
return

/*/	-----------------------------------------------------------------/
Carrega itens do menu lateral e o JavaScript para exclusão dos posts
/-------------------------------------------------------------------*/
static function loadPage()	
	
    // --------------------------------------------------------------------------------
	// Insere itens no menu lateral
    // --------------------------------------------------------------------------------
	BeginContent var cMenu
      <a href="javascript:void(0)" class="closebtn" onclick="closeNav()">&#9754;&nbsp;</a>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('inserePosts', 'Insere posts');">Insere posts</a>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('deleteFirst', 'Deleta primeiro post');">Deleta 1o post</a>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('countPosts', 'Exibe a quantidade de posts');">Posts visiveis</a>
      <hr>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('takePicture', 'Captura imagem');">Captura foto</a>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('getGeoCoordinate', 'Retorna geolocalizacao');">Geolocaliza&ccedil;&atilde;o</a>
      <hr>
      <a href="#" onclick="closeNav(); dialog.jsToAdvpl('closeApp', 'Aplicacao fechada manualmente');">Sair</a>
	endContent
	oWebChannel:advplToJs("lateralMenu", cMenu)

    // --------------------------------------------------------------------------------
    // Insere trecho JavaScript para delecao dos posts
    // --------------------------------------------------------------------------------
    // Serao 2 tipos de deleção: 1o Apaga o primeiro post da lista, chamado pelo menu lateral
    //                           2o Apaga o post atraves do botao fechar (X) do proprio post
    // --------------------------------------------------------------------------------
    // *IMPORTANTE: Nunca utilize comentarios ao inserir o codigo JavaScript via AdvPL
    // --------------------------------------------------------------------------------
    BeginContent var cFunction
    	
    	function removeFirstPanel() {
            var lenPosts = document.getElementById("mainPanel").childNodes.length;
            for (i=0; i<lenPosts; i++) {
                if (document.getElementById("mainPanel").childNodes[i].id == "panelID") {
                    document.getElementById("mainPanel").childNodes[i].remove();
                    break;
                }                   
            }
    	}
    
    	function removePanel(obj, avatarNum) {
    		obj.parentElement.parentElement.remove();
    		dialog.jsToAdvpl("deletePost", avatarNum);
    	}
    	
    endContent
	oWebChannel:advplToJs("js", cFunction)

return

/*/	-----------------------------------------------------------------/
Alert que sera executado via JavaScript
/-------------------------------------------------------------------*/
static function jsAlert(cTitle, cText)
	oMiniPost:oWebEngine:runJavaScript('jsAlert("' +cTitle+ '", "' +cText+ '");')
return

/*/	-----------------------------------------------------------------/
Classe AdvPL para manipulação do componente TWebEngine
/-------------------------------------------------------------------*/
class miniPost
	Data nCount
	Data nLastPost
	Data oWebEngine
		
	Method new(oWnd,nRow,nCol,nWidth,nHeight,cUrl) CONSTRUCTOR
	Method count()
	Method insere()
	Method deletaFirst()
endClass
	
/*/	-----------------------------------------------------------------/
Construtor
/-------------------------------------------------------------------*/
Method New(oWnd,nRow,nCol,nWidth,nHeight,cUrl) class miniPost
	::oWebEngine := TWebEngine():New(oWnd,nRow,nCol,nWidth,nHeight,cUrl)
	::nCount := 0
	::nLastPost := 0
return

/*/	-----------------------------------------------------------------/
Retorna quantidade de posts
/-------------------------------------------------------------------*/
Method count() class miniPost
return ::nCount

/*/	-----------------------------------------------------------------/
Insere 6 posts
/-------------------------------------------------------------------*/
Method insere() class miniPost
local cAvatar, cField, i

	for i := 1 to 6
		::nCount++
		::nLastPost++
		
		cAvatar := cValToChar(::nLastPost)
		cAvatarImage := cValToChar(i)

		// Insere posts
		BeginContent var cField
	    <div id="panelID" class="panel panel-default" style="border-spacing:5px;">
	        <div class="media-left">
	        	<img onclick="jsAlert('Avatar', 'Selecionado <b>Avatar%Exp:cAvatar%</b>, mensagem enviada ao Servidor'); dialog.jsToAdvpl('Selecionado avatar', 'Avatar%Exp:cAvatar%')" 
	        		src="img_avatar%Exp:cAvatarImage%.png" class="media-object" style="width:60px">
	        </div>
	        <div class="media-body">
	            <button class="close" onclick="removePanel(this, 'Avatar%Exp:cAvatar%');">
	                <span aria-hidden="true">&times;</span></button>
	            <h4 class="media-heading">Avatar%Exp:cAvatar%</h4>
	            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
	        </div>
	    </div>
	    endContent
		oWebChannel:advplToJs("insertPost", cField)
		
	next i

return

/*/	-----------------------------------------------------------------/
Deleta primeiro post
/-------------------------------------------------------------------*/
Method deletaFirst() class miniPost
	if ::nCount > 0
		::nCount--
		::oWebEngine:runJavaScript("removeFirstPanel()")
	endif
return
