// Reproduce the approved A+ paper/ornament as uncompressed client-readable TGA.
// Development-only: Node, Playwright, Chromium and ImageMagick; no addon dependency.
const fs=require('fs'),path=require('path'),http=require('http'),os=require('os');
const {execFileSync}=require('child_process');
const {chromium}=require('playwright');
(async()=>{
 const root=path.resolve(__dirname,'../..');
 const html=fs.readFileSync(path.join(__dirname,'parchment-material.html'));
 const server=http.createServer((req,res)=>{res.setHeader('Content-Type','text/html');res.end(html)});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'parchment-assets-'));
 let browser;
 try{
  browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox']});
  const page=await browser.newPage({viewport:{width:300,height:300},deviceScaleFactor:1});
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  for(const [selector,name,opaque] of [['.paper','ParchmentPage',true],['.ornament','ParchmentRule',false]]){
   const png=path.join(tmp,name+'.png');
   await page.locator(selector).screenshot({path:png,omitBackground:true});
   const args=[png,...(opaque?['-alpha','off','-type','TrueColor']:['-type','TrueColorAlpha']),'-depth','8','-compress','none',path.join(root,'ZygorGuidesViewerRM/Skin',name+'.tga')];
   execFileSync('convert',args);
  }
 }finally{if(browser)await browser.close();server.close();fs.rmSync(tmp,{recursive:true,force:true})}
 console.log('Generated A+ paper 256x256 and ornament 128x16.');
})().catch(e=>{console.error(e);process.exitCode=1});
