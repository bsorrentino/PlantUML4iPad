import fs from "fs-extra";
import path from "path";

const srcPath = path.join('.', 'node_modules', 'ace-builds', 'src-min-noconflict' ) 
// const targetPath = "dist";
const targetPath = path.join( '..', 'Sources', 'CodeViewer', 'Resources', 'ace.bundle')

const copyFiles = async () => {

    const filter = async (src, dest) => { 
        
        const stat = await fs.lstat(src);
        
        if(stat.isDirectory()) {
            return true;
        }

        const fileName = path.basename(src)

        return  fileName.startsWith('ext-') ||
                fileName.startsWith('theme-') || 
                fileName === 'mode-plain_text.js' ||
                fileName === 'mode-dot.js' ||
                fileName === 'worker-base.js' ||
                fileName === 'ace.js' || 
                fileName === 'plain_text.js' ||
                fileName === 'dot.js'
            ;
    }
    return fs.copy( srcPath, targetPath, { overwrite: true, filter: filter, recursive: true } )
}

copyFiles()
.then(() => console.info( "files copied!") )
