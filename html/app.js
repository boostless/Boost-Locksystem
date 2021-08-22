function main(){
    return {
        show: false,
        plate: 'Plate',
        lock(){
            postData('https://Boost-Locksystem/Lock', {plate: this.plate})
        },
        unlock(){
            postData('https://Boost-Locksystem/Unlock', {plate: this.plate})
        },
        engine(){
            postData('https://Boost-Locksystem/Engine', {plate: this.plate})
        },
        listen(){
            window.addEventListener('message', (event) => {
                let data = event.data
                this.show = data.show
                this.plate = data.plate
            })

            document.onkeyup = function(event){
                if(event.key == "Escape"){
                    postData('https://Boost-Locksystem/Close', {})
                    this.show = false
                }
            };
        }
    }
}

async function postData(url = '', data = {}) {
    const response = await fetch(url, {
      method: 'POST', // *GET, POST, PUT, DELETE, etc.
      mode: 'cors', // no-cors, *cors, same-origin
      cache: 'no-cache', // *default, no-cache, reload, force-cache, only-if-cached
      credentials: 'same-origin', // include, *same-origin, omit
      headers: {
        'Content-Type': 'application/json'
      },
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: JSON.stringify(data)
    });
    return response.json();
  }
