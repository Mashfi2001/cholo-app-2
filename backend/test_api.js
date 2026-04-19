const fs = require('fs');
const axios = require('axios');
const FormData = require('form-data');
const path = require('path');

async function testSubmit() {
  try {
    const imgData = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==";
    fs.writeFileSync('test.png', Buffer.from(imgData, 'base64'));

    const form = new FormData();
    form.append('userId', '1');
    form.append('documentType', 'NID');
    // Using a filename without extension
    form.append('document', fs.createReadStream('test.png'), {
      filename: 'image_picker_F938FD83', 
      contentType: 'image/jpeg'
    });

    const response = await axios.post('http://localhost:3000/api/verification/submit', form, {
      headers: {
        ...form.getHeaders()
      }
    });

    console.log("Success:", response.data);
  } catch (error) {
    console.error("Error:", error.response ? error.response.data : error.message);
  }
}

testSubmit();
