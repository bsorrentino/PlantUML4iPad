import fs from "fs-extra";
import path from "path";


// const targetPath = "dist";
const targetPath = path.join( '..', 'Sources', 'CodeViewer', 'Resources', 'ace.bundle')

const copyModesAndSnippet = async () => {
    const srcPath = path.join('.', 'node_modules', 'ace-builds', 'src-noconflict' ) 

    const filter = async (src, dest) => { 
        
        const stat = await fs.lstat(src);
        
        if(stat.isDirectory()) {
            return true;
        }

        const fileName = path.basename(src)

        return  fileName === 'mode-plantuml.js'   ||
                fileName === 'plantuml.js'        
            ;
    }
    return fs.copy( srcPath, targetPath, { overwrite: true, filter: filter, recursive: true } )

}

const copyFiles = async () => {
    const srcPath = path.join('.', 'node_modules', 'ace-builds', 'src-noconflict' ) 
    
    const filter = async (src, dest) => { 
        
        const stat = await fs.lstat(src);
        
        if(stat.isDirectory()) {
            return true;
        }

        const fileName = path.basename(src)

        return  fileName === 'ace.js'               || 
                fileName === 'worker-base.js'       ||
                fileName.startsWith('ext-')         ||
                fileName.startsWith('theme-')       
            ;
    }
    return fs.copy( srcPath, targetPath, { overwrite: true, filter: filter, recursive: false } )
}

copyFiles()
.then( copyModesAndSnippet )
.then(() => console.info( "files copied!") )
