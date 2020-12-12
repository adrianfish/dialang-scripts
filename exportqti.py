import psycopg2
import psycopg2.extras
import os
from string import Template

prologue_template = Template("""
<?xml version="1.0" encoding="UTF-8"?>
    <qti-assessment-item xmlns="http://www.imsglobal.org/xsd/imsqtiasi_v3p0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation=" http://www.imsglobal.org/xsd/imsqtiasi_v3p0 https://purl.imsglobal.org/spec/qti/v3p0/schema/xsd/imsqti_asiv3p0_v1p0.xsd "
        identifier="$identifier"
        title="$title">
""")

# Connect to your postgres DB
conn = psycopg2.connect("dbname=DIALANG user=dialangadmin password=dialangadmin")

# Open a cursor to perform database operations
cur = conn.cursor(cursor_factory = psycopg2.extras.DictCursor)

# Execute a query
cur.execute("SELECT * FROM baskets where parent_testlet_id IS NULL")

# Retrieve query results
baskets = cur.fetchall()

if not os.path.exists('baskets'):
    os.mkdir('baskets')

dir_fd = os.open('baskets', os.O_RDONLY)

type_mapping = {
    "mcq": "choice",
    "shortanswer": "textEntry",
    "gaptext": "textEntry",
    "gapdrop": "choice",
    "tabbedpane": "choice",
}

def opener(path, flags):
    return os.open(path, flags, dir_fd=dir_fd)

for basket in baskets:
    with open(f'{basket["id"]}.xml', 'w', opener=opener) as f:
        print(prologue_template.substitute(identifier=type_mapping[basket['type']], title='balls'), file=f)
        print('\t\t<qti-item-body>', file=f)
        if basket['textmedia'] is not None:
            print(basket['textmedia'], file=f)

        if basket['type'] == 'mcq':
            cur.execute("SELECT * FROM items WHERE items.id IN (SELECT item_id from baskets b, basket_item where type  = 'mcq' and basket_id = b.id and b.id = " + str(basket["id"]) + ")")
            items = cur.fetchall()
            for item in items:
                print('\t\t\t<qti-choice-interaction response-identifier="RESPONSE" shuffle="false" max-choices="1">', file=f)
                print('\t\t\t\t<qti-prompt>' + item['text'] + '</qti-prompt>', file=f)
                cur.execute("SELECT text, correct FROM answers WHERE item_id = " + str(item['id']))
                answers = cur.fetchall()
                corrects = []
                for num, answer in enumerate(answers, start=1):
                    if answer["correct"]:
                        corrects.append(num)
                    print('\t\t\t\t<qti-simple-choice identifier="' + str(num) + '">' + answer['text'] + '</qti-simple-choice>', file=f)

                print('\t\t\t</qti-choice-interaction>', file=f)
        
        print('\t\t</qti-item-body>', file=f)
        print('\t\t<qti-response-declaration identifier="RESPONSE" cardinality="single" base-type="identifier">', file=f)
        for correct in corrects:
            print('\t\t\t<qti-correct-response><qti-value>' + str(correct) + '</qti-value></qti-correct-response>', file=f)
        print('\t\t</qti-response-declaration>', file=f)
        print("\t</qti-assessment-item>", file=f)

os.close(dir_fd)
