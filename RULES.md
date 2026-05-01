```ts
// !deadline-ts.customFinishSector_FinishModulesEnd
// The comment above is required for deadline-ts to parse this code correctly. You place the comment above this comment to define the end of all import statements.

// If you want to write on this program, you will follow the following Terms of Service. Failure to obey with the ToS is an illegal action and can lead to severe consequences.
// Here is the Gigachad Terms of Service 2000 Iteration 0
/* Terms of Service

SECTION 1 - DO NOT BE LAZY:
- Make things extensible and modular as possible, then think about you can extend this in the future. This means: no hardcoding, allow composition and allow things from the outside to set abritary things rather than fixed to a defined set.
- Never abbreviate variable names. EVER: They must be readable in English, and understandable. Include all details and context inside that variable name. More details is better. Utilise camelCase.
- NEVER. EVER. USE. ALIGNMENT SPACES—They're ugly, ignored by beautifiers, and no one ever uses them.
Examples of this bad practice:
const abanana = dog;
const ba      = dog2;
const fucku   = fuckingdog;
Examples of a good practice:
const abanana = dog;
const ba = dog2;
const fucku = fuckingdog;
- Always do the best implementation you can. Never skip out on things or do simpler versions. This is very important. If you do become lazy and do a worse implementation, problems in the future can happen because of that.

SECTION 2 - CONSISTENCY AND CODE STYLE:
- Use existing code style and don't add weird spaces between stuff like assigment statements.
- Embrace never-nesting practices—Use early guard clauses and remember continue statement exists.
- Include all details within your edit and never EVER hardcode anything to fill one cause. Other things from outside must be able to edit your cause in a different way to the extend I could add 50 dogs on top of a simple metal reflective box object and turn the box into a polygon that flashes rainbow every two seconds before turning into a yellow dog as an example.
- Split concerns across multiple things—Don't make one thing handle it all—Allow for us to retrieve all values from data instead of just stealing one value and running away—This is for extensibility in the future. 
Example of bad practice:
const ax = (DogArrayData as {dogNameTag: string} & number[])[0];
Example of good practice:
const customDogArray: dogArrayType = DogArrayData;
const firstElementInDogArray = customDogArray[0];
- Inheritance is mostly outdated—so unless you're directly touching TypeScript stuff (like classes) or something, a pattern of composition is preferred unless you are forced to use it.
- A space around each side of an arithmetic operator is generally advised.

SECTION 3 - TYPESCRIPT BEST PRACTICES:
- If possible, never use `as` statements in TypeScript—This is considered terrible practice.
- Never use the `any` type unless embedding it into another thing that basically requires you to do it, or any existing code has it that you can copy from. Example: assign statement. It already uses Record<string, any> - and you can't edit that file to fix it for a better type. Then, you would use Record<string, any>.
- If there is a more suitable type available—use it. Example: Record<string, unknown> could lead to errors when trying to do {dog: new Vector3()}; A better practice would to usePartial<InstanceProperties<BasePart>> or InstanceProperties<BasePart> depending on the context.

SECTION 4 - COMMON SENSE AND BEST PRACTICES:
- If something you suspect might be wrong—don't adapt your code on that. Do not build on mistakes; Do not make your code based on that mistake—Spot that it's a mistake and if you have been granted permission to edit that part, edit to fix. Otherwise, just inform us.
- Don't truncate things—ugly.
- Don't add comments that point the obvious. Unless you're explaining some nuanced thing or detail, maybe an algorithm — Just don't.
- Don't use outdated APIs or versions—Always refer to newer alternatives rather than using deprecated things in new code.
- If you can avoid an else statement using stuff like lookup tables or continue statement, do it.

By editing on this file, you agree to the terms of conditions. Misconduct will result in your access being revoked and session terminated.

Think of it like this:
┌─────────────────────────────────────────────┐
│             Visual Studio Code              │
├─────────────────────────────────────────────┤
│ This code is ass. Session Terminated.       │
│                                             │
│ [I WILL FIX THIS]                           │
└─────────────────────────────────────────────┘
*/
```